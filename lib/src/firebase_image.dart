import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'cache_manager.dart';
import 'image_fetch_strategy.dart';

typedef FirebaseImageError = Uint8List Function(Exception exception);

class FirebaseImage extends ImageProvider<FirebaseImage> {
  // Default: True. Specified whether or not an image should be cached (optional)
  final bool shouldCache;

  /// Default: 1.0. The scale to display the image at (optional)
  final double scale;

  /// Default: 2.5MB. The maximum size in bytes to be allocated in the device's memory for the image (optional)
  final int maxSizeBytes;

  /// Default: BY_METADATA_DATE. Specifies the strategy in which to check if the cached version should be refreshed (optional)
  final CacheRefreshStrategy cacheRefreshStrategy;

  /// Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from (optional)
  final FirebaseApp firebaseApp;

  /// The model for the image object
  final FirebaseImageObject _imageObject;

  /// Default: FETCH_TO_MEMORY. Specifies the strategy in which to fetch the image from Firebase (optional)
  final ImageFetchStrategy imageFetchStrategy;

  /// An optional response to when an error occurs (optional)
  final FirebaseImageError onError;

  final FirebaseImageCacheManager _cacheManager;

  /// Fetches, saves and returns an ImageProvider for any image in a readable Firebase Cloud Storeage bucket.
  ///
  /// [location] The URI of the image, in the bucket, to be displayed
  /// [shouldCache] Default: True. Specified whether or not an image should be cached (optional)
  /// [scale] Default: 1.0. The scale to display the image at (optional)
  /// [maxSizeBytes] Default: 2.5MB. The maximum size in bytes to be allocated in the device's memory for the image (optional)
  /// [cacheRefreshStrategy] Default: BY_METADATA_DATE. Specifies the strategy in which to check if the cached version should be refreshed (optional)
  /// [firebaseApp] Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from (optional)
  FirebaseImage(
    String location, {
    this.shouldCache = true,
    this.scale = 1.0,
    this.maxSizeBytes = 2500 * 1000, // 2.5MB
    this.cacheRefreshStrategy = CacheRefreshStrategy.BY_METADATA_DATE,
    this.firebaseApp,
    this.imageFetchStrategy = ImageFetchStrategy.FETCH_TO_MEMORY,
    this.onError,
  }) : _imageObject = FirebaseImageObject(
          bucket: _getBucket(location),
          remotePath: _getImagePath(location),
          reference: _getImageRef(location, firebaseApp),
        ),
      _cacheManager = FirebaseImageCacheManager(
        cacheRefreshStrategy: cacheRefreshStrategy,
        imageFetchStrategy: imageFetchStrategy,
      );

  /// Returns the image as bytes
  Future<Uint8List> getBytes() {
    return _fetchImage();
  }

  static String _getBucket(String location) {
    final uri = Uri.parse(location);
    return '${uri.scheme}://${uri.authority}';
  }

  static String _getImagePath(String location) {
    final uri = Uri.parse(location);
    return uri.path;
  }

  static Reference _getImageRef(String location, FirebaseApp firebaseApp) {
    FirebaseStorage storage = FirebaseStorage.instanceFor(
        app: firebaseApp, bucket: _getBucket(location));
    return storage.ref().child(_getImagePath(location));
  }

  Future<Uint8List> _fetchImage() async {
    Uint8List bytes;

    try {
      if (shouldCache) {
        await _cacheManager.open();
        FirebaseImageObject localObject =
        await _cacheManager.get(_imageObject.uri, this);

        if (localObject != null) {
          bytes = await _cacheManager.localFileBytes(localObject);
          if (bytes == null) {
            bytes = await _cacheManager.upsertRemoteFileToCache(
              _imageObject, this.maxSizeBytes);
          }
        } else {
          bytes = await _cacheManager.upsertRemoteFileToCache(
            _imageObject, this.maxSizeBytes);
        }
      } else {
        bytes =
        await _cacheManager.remoteFileBytes(_imageObject, this.maxSizeBytes);
      }
    }
    catch (ex) {
      await delete();

      if (this.onError != null) {
        bytes = this.onError(ex);
      }
    }

    return bytes;
  }

  Future<Codec> _fetchImageCodec() async {
    return await PaintingBinding.instance
        .instantiateImageCodec(await _fetchImage());
  }

  Future<bool> delete() async {
    await _cacheManager.open();
    await _cacheManager.delete(_imageObject.uri);

    return super.evict();
  }

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(FirebaseImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: key._fetchImageCodec(),
      scale: key.scale,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final FirebaseImage typedOther = other;
    return _imageObject.uri == typedOther._imageObject.uri &&
        this.scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(_imageObject.uri, this.scale);

  @override
  String toString() =>
      '$runtimeType("${_imageObject.uri}", scale: ${this.scale})';
}

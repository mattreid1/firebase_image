import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cache_manager.dart';
import 'cache_refresh_strategy.dart';
import 'image_object.dart';

@immutable
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
  final FirebaseApp? firebaseApp;

  /// Image to show when a trouble occur
  final String errorAssetImage;

  /// The model for the image object
  final FirebaseImageObject _imageObject;

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
    required this.errorAssetImage,
    this.shouldCache = true,
    this.scale = 1.0,
    this.maxSizeBytes = 2500 * 1000, // 2.5MB
    this.cacheRefreshStrategy = CacheRefreshStrategy.BY_METADATA_DATE,
    this.firebaseApp,
  }) : _imageObject = FirebaseImageObject(
          bucket: _getBucket(location),
          remotePath: _getImagePath(location),
          reference: _getImageRef(location, firebaseApp),
        );

  static String _getBucket(String location) {
    final uri = Uri.parse(location);
    return '${uri.scheme}://${uri.authority}';
  }

  static String _getImagePath(String location) {
    final uri = Uri.parse(location);
    return uri.path;
  }

  static Reference _getImageRef(String location, FirebaseApp? firebaseApp) {
    var storage = FirebaseStorage.instanceFor(
        app: firebaseApp, bucket: _getBucket(location));
    return storage.ref().child(_getImagePath(location));
  }

  Future<ImmutableBuffer> _fetchImage() async {
    Uint8List? bytes;
    final cacheManager = FirebaseImageCacheManager(
      cacheRefreshStrategy,
    );

    if (shouldCache) {
      await cacheManager.open();
      var localObject = await cacheManager.get(_imageObject.uri, this);

      if (localObject != null) {
        bytes = await cacheManager.localFileBytes(localObject);
        if (bytes == null) {
          bytes = await cacheManager.upsertRemoteFileToCache(
              _imageObject, maxSizeBytes);
        }
      } else {
        try {
          bytes = await cacheManager.upsertRemoteFileToCache(
              _imageObject, maxSizeBytes);
        } on FirebaseException catch (_) {
          bytes = (await rootBundle.load(errorAssetImage)).buffer.asUint8List();
        }
      }
    } else {
      bytes = await cacheManager.remoteFileBytes(_imageObject, maxSizeBytes);
    }

    return ImmutableBuffer.fromUint8List(bytes!);
  }

  Future<Codec> _fetchImageCodec() async {
    return await PaintingBinding.instance
        .instantiateImageCodecFromBuffer(await _fetchImage());
  }

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(
      FirebaseImage key,
      Future<Codec> Function(Uint8List,
              {bool allowUpscaling, int? cacheHeight, int? cacheWidth})
          decode) {
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
        scale == typedOther.scale;
  }

  @override
  int get hashCode => this.hashCode;

  @override
  String toString() => '$runtimeType("${_imageObject.uri}", scale: $scale)';
}

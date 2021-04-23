import 'dart:typed_data';
import 'dart:ui';
import 'dart:convert' show base64Decode;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager/universal.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final Uint8List emptyImagePlaceholder = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV/TSv2oONhBxCFDdbIgWsRRq1CECqFWaNXB5NIvaNKQpLg4Cq4FBz8Wqw4uzro6uAqC4AeIm5uToouU+L+00CLGg+N+vLv3uHsHCPUy06zABKDptplKxMVMdlUMviKAHvQhhkGZWcacJCXhOb7u4ePrXZRneZ/7c/SrOYsBPpF4lhmmTbxBPL1pG5z3icOsKKvE58TjJl2Q+JHrSpPfOBdcFnhm2Eyn5onDxGKhg5UOZkVTI44RR1RNp3wh02SV8xZnrVxlrXvyF4Zy+soy12mOIIFFLEGCCAVVlFCGjSitOikWUrQf9/APu36JXAq5SmDkWEAFGmTXD/4Hv7u18lOTzaRQHOh6cZyPUSC4CzRqjvN97DiNE8D/DFzpbX+lDsx8kl5ra5EjYGAbuLhua8oecLkDDD0Zsim7kp+mkM8D72f0TVlg8BboXWv21trH6QOQpq6SN8DBITBWoOx1j3d3d/b275lWfz9Z83Kd00lbqwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+UECQs0OeqvXcUAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAADElEQVQI12P4//8/AAX+Av7czFnnAAAAAElFTkSuQmCC');

Uint8List defaultCallback() {
  return emptyImagePlaceholder;
}

class FirebaseImage extends ImageProvider<FirebaseImage> {
  // Default: True. Specified whether or not an image should be cached (optional)
  final bool shouldCache;

  /// Default: 1.0. The scale to display the image at (optional)
  final double scale;

  // Default null. What to return if no bytes are returned (example: wrong uri, image too large,...)
  final Uint8List Function() getDefaultBytesCallback;

  /// Default: 2.5MB. The maximum size in bytes to be allocated in the device's memory for the image (optional)
  final int maxSizeBytes;

  /// Default: BY_METADATA_DATE. Specifies the strategy in which to check if the cached version should be refreshed (optional)
  final CacheRefreshStrategy cacheRefreshStrategy;

  /// Default: the default Firebase app. Specifies a custom Firebase app to make the request to the bucket from (optional)
  final FirebaseApp? firebaseApp;

  /// The model for the image object
  final FirebaseImageObject _imageObject;

  /// Fetches, saves and returns an ImageProvider for any image in a readable Firebase Cloud Storeage bucket.
  ///
  /// [location] The URI of the image, in the bucket, to be displayed
  /// [getDefaultBytesCallback] Default: null. The bytes to return if no image is fetched.
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
    this.getDefaultBytesCallback = defaultCallback,
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
    FirebaseStorage storage = FirebaseStorage.instanceFor(
        app: firebaseApp, bucket: _getBucket(location));
    return storage.ref().child(_getImagePath(location));
  }

  Future<Uint8List?> _fetchImage() async {
    Uint8List? bytes;
    FirebaseImageCacheManager cacheManager = FirebaseImageCacheManager(
      cacheRefreshStrategy,
    );

    if (shouldCache) {
      await cacheManager.open();
      FirebaseImageObject? localObject =
          await cacheManager.getObject(_imageObject.uri, this);

      if (localObject != null) {
        bytes = await cacheManager.getLocalFileBytes(localObject);
        if (bytes == null) {
          bytes = await cacheManager.upsertRemoteFileToCache(
              _imageObject, this.maxSizeBytes);
        }
      } else {
        bytes = await cacheManager.upsertRemoteFileToCache(
            _imageObject, this.maxSizeBytes);
      }
    } else {
      bytes = await cacheManager.getRemoteFileBytes(
          _imageObject, this.maxSizeBytes);
    }

    return bytes;
  }

  Future<Uint8List> _fetchImageOrDefault() async {
    Uint8List? bytes;
    try {
      bytes = await _fetchImage();
    } on FirebaseException catch (e) {
      // Image does not exist -> silently catch error
      bytes = null;
    }
    return bytes ?? this.getDefaultBytesCallback();
  }

  Future<Codec> _fetchImageCodec() async {
    return await PaintingBinding.instance!
        .instantiateImageCodec(await _fetchImageOrDefault());
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

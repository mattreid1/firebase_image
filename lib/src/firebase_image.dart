import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/src/cache_manager.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseImage extends ImageProvider<FirebaseImage> {
  // Should the image be cached (optional)
  final bool shouldCache;

  /// The scale to display the image at (optional)
  final double scale;

  /// The maximum size in bytes to be allocated on the device for the image (optional)
  final int maxSizeBytes;

  /// The Firebase app to make the request from (optional)
  final FirebaseApp firebaseApp;

  ///
  FirebaseImageObject _imageObject;

  /// TODO: Add descriptions
  ///
  /// [location]
  /// [shouldCache]
  /// [maxSizeBytes]
  /// [firebaseApp]
  FirebaseImage(
    String location, {
    this.shouldCache = true,
    this.scale = 1.0,
    this.maxSizeBytes = 2500 * 1000, // 2.5MB
    FirebaseApp firebaseApp,
  })  : this.firebaseApp = firebaseApp,
        _imageObject = FirebaseImageObject(
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

  static StorageReference _getImageRef(
      String location, FirebaseApp firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage(app: firebaseApp, storageBucket: _getBucket(location));
    return storage.ref().child(_getImagePath(location));
  }

  Future<Codec> _fetchImage() async {
    Uint8List bytes;
    FirebaseImageCacheManager cacheManager = new FirebaseImageCacheManager();

    if (shouldCache) {
      await cacheManager.open();
      FirebaseImageObject localObject =
          await cacheManager.get(_imageObject.uri);

      if (localObject != null) {
        bytes = await cacheManager.localFileBytes(localObject);
        if (bytes == null) {
          bytes = await cacheManager.upsertRemoteFileToCache(
              _imageObject, this.maxSizeBytes);
        }
      } else {
        bytes = await cacheManager.upsertRemoteFileToCache(
            _imageObject, this.maxSizeBytes);
      }
    } else {
      bytes = await cacheManager.remoteFileBytes(_imageObject, this.maxSizeBytes);
    }

    cacheManager.close();
    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(FirebaseImage key) {
    return MultiFrameImageStreamCompleter(
        codec: key._fetchImage(), scale: key.scale);
  }
}

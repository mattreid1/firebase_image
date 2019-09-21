library firebase_image_cache;

import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FirebaseImage extends ImageProvider<FirebaseImage> {
  /// The URI of the image
  final String location;

  // Should the image be cached (optional)
  final bool shouldCache;

  /// The scale to display the image at (optional)
  final double scale;

  /// The maximum size in bytes to be allocated on the device for the image (optional)
  final int maxSizeBytes;

  /// The Firebase app to make the request from (optional)
  final FirebaseApp _firebaseApp;

  /// TODO: Add descriptions
  ///
  /// [location]
  /// [shouldCache]
  /// [maxSizeBytes]
  /// [firebaseApp]
  const FirebaseImage(
    this.location, {
    this.shouldCache = true,
    this.scale = 1.0,
    this.maxSizeBytes = 2500 * 1000, // 2.5MB
    FirebaseApp firebaseApp,
  }) : _firebaseApp = firebaseApp;

  Future<Codec> _fetch() async {
    final uri = Uri.parse(location);

    FirebaseStorage storage = FirebaseStorage(
        app: _firebaseApp, storageBucket: '${uri.scheme}://${uri.authority}');
    final bytes = await storage.ref().child(uri.path).getData(maxSizeBytes);

    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  Future<FirebaseImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FirebaseImage>(this);
  }

  @override
  ImageStreamCompleter load(FirebaseImage key) {
    return MultiFrameImageStreamCompleter(
        codec: key._fetch(), scale: key.scale);
  }
}

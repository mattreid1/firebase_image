import 'dart:typed_data';

import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';

abstract class AbstractFirebaseImageCacheManager {
  final CacheRefreshStrategy cacheRefreshStrategy;

  AbstractFirebaseImageCacheManager(
    this.cacheRefreshStrategy,
  );

  Future<void> open() async {}

  Future<void> close() async {}

  Future<FirebaseImageObject?> getObject(
      String uri, FirebaseImage image) async {
    throw UnimplementedError();
  }

  Future<List<FirebaseImageObject>> getAllObjects() async {
    throw UnimplementedError();
  }

  Future<Uint8List?> getLocalFileBytes(FirebaseImageObject? object) async {
    throw UnimplementedError();
  }

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes) async {
    throw UnimplementedError();
  }

  Future<Uint8List?> getRemoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes) {
    return object.reference.getData(maxSizeBytes);
  }

  Future<int> getRemoteVersion(
      FirebaseImageObject object, int defaultValue) async {
    return (await object.reference.getMetadata())
            .updated
            ?.millisecondsSinceEpoch ??
        defaultValue;
  }

  Future<void> checkForUpdate(
      FirebaseImageObject object, FirebaseImage image) async {
    int remoteVersion = await getRemoteVersion(object, -1);
    if (remoteVersion != object.version) {
      // If true, download new image for next load
      await this.upsertRemoteFileToCache(object, image.maxSizeBytes);
    }
  }
}

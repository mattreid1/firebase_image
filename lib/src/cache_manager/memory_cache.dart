import 'dart:typed_data';

import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager/abstract.dart';
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';

class MemoryCacheEntry {
  /// Model for an entry in the memory cache
  FirebaseImageObject object;
  Uint8List? bytes;

  MemoryCacheEntry({
    required this.object,
    required this.bytes,
  });
}

class FirebaseImageCacheManager extends AbstractFirebaseImageCacheManager {
  /// Key is the URI of the image
  final memoryCache = Map<String, MemoryCacheEntry>();

  FirebaseImageCacheManager(cacheRefreshStrategy) : super(cacheRefreshStrategy);

  // Interface methods

  Future<FirebaseImageObject?> getObject(
      String uri, FirebaseImage image) async {
    final cacheEntry = memoryCache[uri];
    if (cacheEntry == null) {
      return null;
    } else {
      final returnObject = cacheEntry.object;
      if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
        checkForUpdate(returnObject, image); // Check for update in background
      }
      return returnObject;
    }
  }

  Future<List<FirebaseImageObject>> getAllObjects() async {
    final List<FirebaseImageObject> objects = [];
    memoryCache.forEach((k, v) => objects.add(v.object));
    return objects;
  }

  Future<Uint8List?> getLocalFileBytes(FirebaseImageObject? object) async {
    final cacheEntry = memoryCache[object?.uri];
    return cacheEntry?.bytes;
  }

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes) async {
    if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
      object.version = await getRemoteVersion(object, 0);
    }
    Uint8List? bytes = await getRemoteFileBytes(object, maxSizeBytes);

    // "store" bytes in memory
    memoryCache[object.uri] = MemoryCacheEntry(object: object, bytes: bytes);

    return bytes;
  }
}

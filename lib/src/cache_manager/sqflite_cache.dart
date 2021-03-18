import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/cache_manager/abstract.dart';
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class FirebaseImageCacheManager extends AbstractFirebaseImageCacheManager {
  static const String key = 'firebase_image';

  late Database db;
  static const String dbName = '$key.db';
  static const String table = 'images';
  late String basePath;

  FirebaseImageCacheManager(cacheRefreshStrategy) : super(cacheRefreshStrategy);

  // Interface methods

  Future<void> open() async {
    db = await openDatabase(
      join((await getDatabasesPath())!, dbName),
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            uri TEXT PRIMARY KEY,
            remotePath TEXT, 
            localPath TEXT, 
            bucket TEXT, 
            version INTEGER
          )
        ''');
      },
      version: 1,
    );
    basePath = await _fileCreatePath();
  }

  Future<void> close() => db.close();

  Future<FirebaseImageObject?> getObject(
      String uri, FirebaseImage image) async {
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: const [
        'remotePath',
        'localPath',
        'bucket',
        'version',
      ],
      where: 'uri = ?',
      whereArgs: [uri],
    );
    if (maps.length > 0) {
      FirebaseImageObject returnObject =
          FirebaseImageObject.fromMap(maps.first);
      returnObject.reference = _getImageRef(returnObject, image.firebaseApp);
      if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
        checkForUpdate(returnObject, image); // Check for update in background
      }
      return returnObject;
    }
    return null;
  }

  Future<Uint8List?> getLocalFileBytes(FirebaseImageObject? object) async {
    if (await _fileExists(object)) {
      return File(object!.localPath!).readAsBytes();
    }
    return null;
  }

  Future<Uint8List?> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes) async {
    if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
      object.version = (await object.reference.getMetadata())
              .updated
              ?.millisecondsSinceEpoch ??
          0;
    }
    Uint8List? bytes = await getRemoteFileBytes(object, maxSizeBytes);
    await _filePut(object, bytes);
    return bytes;
  }

  // Firestore&-related methods

  Reference _getImageRef(FirebaseImageObject object, FirebaseApp? firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: object.bucket);
    return storage.ref().child(object.remotePath);
  }

  // Filesystem-related methods

  Future<String> _fileCreatePath() async {
    final directory = await getTemporaryDirectory();
    return join(directory.path, key);
  }

  Future<bool> _fileExists(FirebaseImageObject? object) async {
    if (object?.localPath == null) {
      return false;
    }
    return File(object!.localPath!).exists();
  }

  Future<FirebaseImageObject> _filePut(
      FirebaseImageObject object, final bytes) async {
    String path = basePath + "/" + object.remotePath;
    path = path.replaceAll("//", "/");
    //print(join(basePath, object.remotePath)); Join isn't working?
    final localFile = await File(path).create(recursive: true);
    await localFile.writeAsBytes(bytes);
    object.localPath = localFile.path;
    return await _dbUpsert(object);
  }

  // DB-related methods

  Future<bool> _dbCheckForEntry(FirebaseImageObject object) async {
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: const ['uri'],
      where: 'uri = ?',
      whereArgs: [object.uri],
    );
    return maps.length > 0;
  }

  Future<FirebaseImageObject> _dbInsert(FirebaseImageObject model) async {
    await db.insert(table, model.toMap());
    return model;
  }

  Future<FirebaseImageObject> _dbUpdate(FirebaseImageObject model) async {
    await db.update(
      table,
      model.toMap(),
      where: 'uri = ?',
      whereArgs: [model.uri],
    );
    return model;
  }

  Future<FirebaseImageObject> _dbUpsert(FirebaseImageObject object) async {
    if (await _dbCheckForEntry(object)) {
      return await _dbUpdate(object);
    } else {
      return await _dbInsert(object);
    }
  }

  // DB delete currently not in use
  // Future<int> _dbDelete(String uri) async {
  //   return await db.delete(
  //     table,
  //     where: 'uri = ?',
  //     whereArgs: [uri],
  //   );
  // }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_image/firebase_image.dart';
import 'package:firebase_image/src/firebase_image.dart';
import 'package:firebase_image/src/image_object.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class FirebaseImageCacheManager {
  static const String key = 'firebase_image';

  late Database db;
  static const String dbName = '$key.db';
  static const String table = 'images';
  late String basePath;

  final CacheRefreshStrategy cacheRefreshStrategy;

  FirebaseImageCacheManager(
    this.cacheRefreshStrategy,
  );

  Future<void> open() async {
    var dbPath = (await getDatabasesPath())!;
    db = await openDatabase(
      join(dbPath, dbName),
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
    basePath = await _createFilePath();
  }

  Future<FirebaseImageObject> insert(FirebaseImageObject model) async {
    await db.insert('images', model.toMap());
    return model;
  }

  Future<FirebaseImageObject> update(FirebaseImageObject model) async {
    await db.update(
      table,
      model.toMap(),
      where: 'uri = ?',
      whereArgs: [model.uri],
    );
    return model;
  }

  Future<FirebaseImageObject> upsert(FirebaseImageObject object) async {
    if (await checkDatabaseForEntry(object)) {
      return await update(object);
    } else {
      return await insert(object);
    }
  }

  Future<bool> checkDatabaseForEntry(FirebaseImageObject object) async {
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      columns: const ['uri'],
      where: 'uri = ?',
      whereArgs: [object.uri],
    );
    return maps.length > 0;
  }

  Future<FirebaseImageObject?> get(String uri, FirebaseImage image) async {
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
      returnObject.reference = getImageRef(returnObject, image.firebaseApp);
      if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
        checkForUpdate(returnObject, image); // Check for update in background
      }
      return returnObject;
    }
    return null;
  }

  Reference getImageRef(FirebaseImageObject object, FirebaseApp? firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: object.bucket);
    return storage.ref().child(object.remotePath);
  }

  Future<void> checkForUpdate(
      FirebaseImageObject object, FirebaseImage image) async {
    int remoteVersion =
        (await object.reference.getMetadata()).updated!.millisecondsSinceEpoch;
    if (remoteVersion != object.version) {
      // If true, download new image for next load
      await this.upsertRemoteFileToCache(object, image.maxSizeBytes);
    }
  }

  Future<List<FirebaseImageObject>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return FirebaseImageObject.fromMap(maps[i]);
    });
  }

  Future<int> delete(String uri) async {
    return await db.delete(
      table,
      where: 'uri = ?',
      whereArgs: [uri],
    );
  }

  Future<Uint8List?> localFileBytes(FirebaseImageObject object) async {
    if (await _fileExists(object)) {
      return File(object.localPath).readAsBytes();
    }
    return null;
  }

  Future<Uint8List?> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes) {
    return object.reference.getData(maxSizeBytes);
  }

  Future<Uint8List> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes) async {
    if (CacheRefreshStrategy.BY_METADATA_DATE == this.cacheRefreshStrategy) {
      object.version =
          (await object.reference.getMetadata()).updated!.millisecondsSinceEpoch;
    }
    Uint8List bytes = (await remoteFileBytes(object, maxSizeBytes))!;
    await putFile(object, bytes);
    return bytes;
  }

  Future<FirebaseImageObject> putFile(
      FirebaseImageObject object, final bytes) async {
    String path = basePath + "/" + object.remotePath;
    path = path.replaceAll("//", "/");
    //print(join(basePath, object.remotePath)); Join isn't working?
    final localFile = await File(path).create(recursive: true);
    await localFile.writeAsBytes(bytes);
    object.localPath = localFile.path;
    return await upsert(object);
  }

  Future<bool> _fileExists(FirebaseImageObject object) async {
    return File(object.localPath).exists();
  }

  Future<String> _createFilePath() async {
    final directory = await getTemporaryDirectory();
    return join(directory.path, key);
  }

  Future<void> close() => db.close();
}

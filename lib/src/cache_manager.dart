import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_image/src/image_object.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class FirebaseImageCacheManager {
  static const String key = 'firebase_image';

  Database db;
  String dbName = '$key.db';
  String table = 'images';
  String basePath;

  Future open() async {
    db = await openDatabase(
      join(await getDatabasesPath(), dbName),
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY, 
            remotePath TEXT, 
            localPath TEXT, 
            bucket TEXT, 
            uri TEXT,
            version INTEGER
          )
        ''');
      },
      version: 1,
    );
    basePath = await _createFilePath();
  }

  Future<FirebaseImageObject> insert(FirebaseImageObject model) async {
    model.id = await db.insert('images', model.toMap());
    return model;
  }

  Future<int> update(FirebaseImageObject model) async {
    return await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<dynamic> upsert(FirebaseImageObject object) async {
    if (object.id == -1) {
      return await insert(object);
    } else {
      return await update(object);
    }
  }

  Future<FirebaseImageObject> get(String uri) async {
    List<Map> maps = await db.query(
      table,
      columns: null,
      where: 'uri = ?',
      whereArgs: [uri],
    );
    if (maps.length > 0) {
      return new FirebaseImageObject.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FirebaseImageObject>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return FirebaseImageObject.fromMap(maps[i]);
    });
  }

  Future<int> delete(int id) async {
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Uint8List> localFileBytes(FirebaseImageObject object) async {
    if (await _fileExists(object)) {
      return new File(object.localPath).readAsBytes();
    }
    return null;
  }

  Future<Uint8List> remoteFileBytes(
      FirebaseImageObject object, int maxSizeBytes) {
    return object.reference.getData(maxSizeBytes);
  }

  Future<Uint8List> upsertRemoteFileToCache(
      FirebaseImageObject object, int maxSizeBytes) async {
    object.version = (await object.reference.getMetadata()).updatedTimeMillis;
    Uint8List bytes = await remoteFileBytes(object, maxSizeBytes);
    putFile(object, bytes);
    return bytes;
  }

  Future<FirebaseImageObject> putFile(
      FirebaseImageObject object, final bytes) async {
    var file = await new File(basePath).writeAsBytes(bytes);
    object.localPath = file.path;
    return await upsert(object);
  }

  Future<bool> _fileExists(FirebaseImageObject object) async {
    if (object?.localPath == null) {
      return false;
    }
    return new File(join(object.localPath)).exists();
  }

  Future<String> _createFilePath() async {
    var directory = await getTemporaryDirectory();
    return join(directory.path, key);
  }

  Future<void> close() async => await db.close();
}

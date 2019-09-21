import 'package:firebase_image_cache/src/image_object.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FirebaseImageCacheManager {
  Database db;
  String dbName = 'firebase_image_cache.db';
  String table = 'images';

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
            version INTEGER, 
          )
        ''');
      },
      version: 1,
    );
  }

  Future<FirebaseImageObject> insert(FirebaseImageObject model) async {
    model.id = await db.insert('images', model.toMap());
    return model;
  }

  Future<int> update(FirebaseImageObject model) async {
    return await db.update(
      table,
      model.toMap(),
      where: "id = ?",
      whereArgs: [model.id],
    );
  }

  Future<dynamic> upsert(FirebaseImageObject model) async {
    if (model.id == -1) {
      return await insert(model);
    } else {
      return await update(model);
    }
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
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> close() async => await db.close();
}

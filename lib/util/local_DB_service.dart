import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalUserService {
  static final LocalUserService _instance = LocalUserService._internal();
  static Database? _db;

  factory LocalUserService() {
    return _instance;
  }

  LocalUserService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_local.db');
    print("Creando base de datos en: $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print("Ejecutando onCreate: creando tabla 'users'");
        await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          name TEXT,
          email TEXT,
          photo TEXT,
          major TEXT,
          gender TEXT,
          age INTEGER,
          indoorOutdoorScore INTEGER,
          favoriteCategories TEXT,
          freeTimeSlots TEXT,
          createdAt TEXT,
          synced INTEGER
        )
      ''');
      },
    );
  }

  Future<void> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markUserAsSynced(String uid) async {
    final db = await database;
    await db.update(
      'users',
      {"synced": 1},
      where: 'id = ?',
      whereArgs: [uid],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> clearUsers() async {
    final db = await database;
    await db.delete('users');
  }

  Future<void> debugPrintUsers() async {
    final users = await getUsers();
    for (final user in users) {
      print("Usuario local: ${user['id']} - Synced: ${user['synced']}");
    }
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [uid],
    );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [uid],
    );
  }


}

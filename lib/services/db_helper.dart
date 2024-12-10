import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hedieaty.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL,
          name TEXT,
          email TEXT NOT NULL,
          phone TEXT
        )
      ''');
    });
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final result = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> insertOrUpdateUser(Map<String, dynamic> user) async {
    final db = await database;

    // Check if the user with the given UID exists
    final existingUser = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [user['uid']],
    );

    if (existingUser.isNotEmpty) {
      // User exists, update the record
      await db.update(
        'users',
        user,
        where: 'uid = ?',
        whereArgs: [user['uid']],
      );
      print('User updated: ${user['uid']}');
    } else {
      // User does not exist, insert a new record
      await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('New user inserted: ${user['uid']}');
    }
  }

// Insert a gift
  Future<void> insertGift(Map<String, dynamic> gift) async {
    final db = await database;
    await db.insert('gifts', gift);
  }

// Get gifts for a specific user
  Future<List<Map<String, dynamic>>> getGiftsForUser(String uid) async {
    final db = await database;
    return await db.query('gifts', where: 'uid = ?', whereArgs: [uid]);
  }

// Delete a gift by ID
  Future<void> deleteGift(int id) async {
    final db = await database;
    await db.delete('gifts', where: 'id = ?', whereArgs: [id]);
  }


}


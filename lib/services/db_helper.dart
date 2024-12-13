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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT,
        email TEXT NOT NULL,
        phone TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL,
        event TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        location TEXT,
        date TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion...");
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          price REAL,
          event TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          location TEXT,
          date TEXT
        )
      ''');
    }
  }


  // ================= Utilities =================

  Future<void> recreateDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'hedieaty.db');
    await deleteDatabase(dbPath);
    print('Database recreated.');
    _database = await _initDatabase();
  }

  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
    print("Table $tableName exists: ${result.isNotEmpty}");
    return result.isNotEmpty;
  }

  // ================= Debugging =================

  Future<void> logTableContents(String tableName) async {
    final db = await database;
    final result = await db.query(tableName);
    print("Contents of $tableName: $result");
  }

  // ================= Users =================

// ================= Users =================

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace, // Ensures no duplicates
    );
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<void> insertOrUpdateUser(Map<String, dynamic> user) async {
    final db = await database;

    // Check if the user already exists
    final existingUser = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [user['uid']],
    );

    if (existingUser.isNotEmpty) {
      // Update the existing user
      await db.update(
        'users',
        user,
        where: 'uid = ?',
        whereArgs: [user['uid']],
      );
    } else {
      // Insert as a new user
      await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ================= Gifts =================

  Future<void> insertGift(Map<String, dynamic> gift) async {
    final db = await database;
    await db.insert('gifts', gift, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGiftsForUser(String uid) async {
    final db = await database;
    return await db.query('gifts', where: 'uid = ?', whereArgs: [uid]);
  }

  // ================= Events =================

  Future<void> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    await db.insert('events', event, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEventsForUser(String uid) async {
    final db = await database;
    return await db.query('events', where: 'uid = ?', whereArgs: [uid]);
  }
}

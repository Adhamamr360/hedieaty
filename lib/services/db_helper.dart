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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables...");
    await db.execute('''CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL,
      name TEXT,
      email TEXT NOT NULL,
      phone TEXT)''');
    await db.execute('''CREATE TABLE gifts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      price REAL,
      event TEXT)''');
    await db.execute('''CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      location TEXT,
      date TEXT,
      number_of_gifts INTEGER DEFAULT 0)''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version \$oldVersion to \$newVersion...");
    if (oldVersion < 2) {
      await db.execute('''CREATE TABLE IF NOT EXISTS gifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL,
        event TEXT)''');
      await db.execute('''CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        location TEXT,
        date TEXT,
        number_of_gifts INTEGER DEFAULT 0)''');
    }
    if (oldVersion < 3) {
      await db.execute('''ALTER TABLE events ADD COLUMN number_of_gifts INTEGER DEFAULT 0''');
    }
  }

  // Increment the gift count for a specific event in the local database
  Future<void> incrementEventGiftCount(int eventId) async {
    final db = await database;
    await db.rawUpdate(
      '''
    UPDATE events
    SET number_of_gifts = number_of_gifts + 1
    WHERE id = ?
    ''',
      [eventId],
    );
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
        "SELECT name FROM sqlite_master WHERE type='table' AND name='\$tableName'");
    print("Table \$tableName exists: \${result.isNotEmpty}");
    return result.isNotEmpty;
  }

  Future<void> logTableContents(String tableName) async {
    final db = await database;
    final result = await db.query(tableName);
    print("Contents of \$tableName: \$result");
  }

  // ================= Users =================

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

    final existingUser = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [user['uid']],
    );

    if (existingUser.isNotEmpty) {
      await db.update(
        'users',
        user,
        where: 'uid = ?',
        whereArgs: [user['uid']],
      );
    } else {
      await db.insert(
        'users',
        user,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ================= Gifts =================

  Future<Map<String, String>> getEventNamesForUser(String uid) async {
    final db = await database;

    // Query the events table for the given user
    final events = await db.query(
      'events',
      columns: ['id', 'name'], // Select only the ID and name
      where: 'uid = ?',
      whereArgs: [uid],
    );

    // Map event IDs to their names
    return {for (var event in events) event['id'].toString(): event['name'].toString()};
  }


  Future<void> insertGift(Map<String, dynamic> gift) async {
    final db = await database;
    await db.insert('gifts', gift, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update the event's gift count if the gift has an event
    if (gift['event'] != null) {
      await updateEventGiftCount(gift['event'] as String, 1); // Increase by 1 gift
    }
  }

  Future<List<Map<String, dynamic>>> getGiftsForUser(String uid) async {
    final db = await database;
    return await db.query('gifts', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<List<Map<String, dynamic>>> getGiftsForEvent(String uid, String event) async {
    final db = await database;
    return await db.query('gifts', where: 'uid = ? AND event = ?', whereArgs: [uid, event]);
  }

  Future<void> deleteGift(int id) async {
    final db = await database;

    // Retrieve the gift to get the associated event before deleting
    final gift = await db.query('gifts', where: 'id = ?', whereArgs: [id]);
    if (gift.isNotEmpty) {
      final eventName = gift.first['event'] as String?;

      // Delete the gift
      await db.delete('gifts', where: 'id = ?', whereArgs: [id]);

      // Update the event's gift count if it is associated with an event
      if (eventName != null) {
        await updateEventGiftCount(eventName, -1); // Decrease by 1 gift
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGiftsByEventId(int eventId) async {
    final db = await database;
    return await db.query(
      'gifts',
      where: 'event = ?',
      whereArgs: [eventId.toString()], // Ensure event ID is passed as a string
    );
  }


  // ================= Events =================

  Future<int?> getEventIdByName(String eventName, String uid) async {
    final db = await database;
    final result = await db.query(
      'events',
      columns: ['id'],
      where: 'name = ? AND uid = ?',
      whereArgs: [eventName, uid],
    );
    return result.isNotEmpty ? result.first['id'] as int : null;
  }


  Future<void> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    await db.insert('events', event, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEventsForUser(String uid) async {
    final db = await database;
    return await db.query('events', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> updateEventGiftCount(String eventName, int giftCountChange) async {
    final db = await database;
    final event = await db.query(
      'events',
      where: 'name = ?',
      whereArgs: [eventName],
    );

    if (event.isNotEmpty) {
      final eventId = event.first['id'];
      final currentGiftCount = event.first['number_of_gifts'] as int;
      final updatedGiftCount = currentGiftCount + giftCountChange;

      await db.update(
        'events',
        {'number_of_gifts': updatedGiftCount},
        where: 'id = ?',
        whereArgs: [eventId],
      );
    }
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}

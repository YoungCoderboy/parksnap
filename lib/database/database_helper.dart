import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle_log.dart';

/// Singleton SQLite database helper for ParkSnap vehicle logs.
class DatabaseHelper {
  static const _databaseName = 'parksnap.db';
  static const _databaseVersion = 1;
  static const table = 'vehicle_logs';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id TEXT PRIMARY KEY,
        license_plate TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        entry_timestamp TEXT NOT NULL,
        exit_timestamp TEXT,
        flat_or_visitor_info TEXT DEFAULT '',
        status TEXT NOT NULL DEFAULT 'Inside',
        image_path TEXT DEFAULT '',
        confidence REAL DEFAULT 0.0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migration logic here
  }

  // ─── CRUD Operations ────────────────────────────────────────────────────────

  /// Insert a new vehicle log. Returns inserted row id.
  Future<int> insertLog(VehicleLog log) async {
    final db = await database;
    return await db.insert(
      table,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all logs, newest first.
  Future<List<VehicleLog>> getAllLogs() async {
    final db = await database;
    final maps = await db.query(
      table,
      orderBy: 'entry_timestamp DESC',
    );
    return maps.map((m) => VehicleLog.fromMap(m)).toList();
  }

  /// Retrieve only vehicles currently inside.
  Future<List<VehicleLog>> getInsideLogs() async {
    final db = await database;
    final maps = await db.query(
      table,
      where: 'status = ?',
      whereArgs: ['Inside'],
      orderBy: 'entry_timestamp DESC',
    );
    return maps.map((m) => VehicleLog.fromMap(m)).toList();
  }

  /// Search logs by license plate (partial match).
  Future<List<VehicleLog>> searchLogs(String query) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: 'license_plate LIKE ?',
      whereArgs: ['%${query.toUpperCase()}%'],
      orderBy: 'entry_timestamp DESC',
    );
    return maps.map((m) => VehicleLog.fromMap(m)).toList();
  }

  /// Update an existing log entry.
  Future<int> updateLog(VehicleLog log) async {
    final db = await database;
    return await db.update(
      table,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Stamp exit time and change status to Exited.
  Future<int> checkOutVehicle(String id) async {
    final db = await database;
    return await db.update(
      table,
      {
        'exit_timestamp': DateTime.now().toIso8601String(),
        'status': 'Exited',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a log by id.
  Future<int> deleteLog(String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Count of vehicles currently inside.
  Future<int> countInside() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE status = ?',
      ['Inside'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close the database (call on app dispose).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

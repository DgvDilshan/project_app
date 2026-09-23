import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Bumped to v2 to ensure all new tables (harvests) are created on existing devices
    _database = await _initDB('tea_app_offline_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Increment version for schema changes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS harvests (
          id TEXT PRIMARY KEY,
          farmer_id TEXT NOT NULL,
          collector_id TEXT NOT NULL,
          weight_kg REAL NOT NULL,
          recorded_at TEXT NOT NULL,
          is_correction INTEGER DEFAULT 0,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS pickup_requests');
      await db.execute('DROP TABLE IF EXISTS harvests');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Pickup Requests Table (Offline)
    await db.execute('''
      CREATE TABLE pickup_requests (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        request_date TEXT NOT NULL,
        status TEXT NOT NULL,
        disease_flag TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Harvests Table (Offline)
    await db.execute('''
      CREATE TABLE harvests (
        id TEXT PRIMARY KEY,
        farmer_id TEXT NOT NULL,
        collector_id TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        is_correction INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // --- Pickup Requests ---
  Future<void> insertPickupRequest(Map<String, dynamic> request) async {
    final db = await instance.database;
    await db.insert('pickup_requests', request, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> hasPendingPickupRequest(String farmerId) async {
    final db = await instance.database;
    final result = await db.query(
      'pickup_requests',
      where: 'farmer_id = ? AND status = ?',
      whereArgs: [farmerId, 'pending'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPickupRequests() async {
    final db = await instance.database;
    return await db.query('pickup_requests', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markPickupRequestSynced(String id) async {
    final db = await instance.database;
    await db.update('pickup_requests', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPickupRequestCompleted(String id) async {
    final db = await instance.database;
    await db.update(
      'pickup_requests', 
      {'status': 'completed', 'is_synced': 0}, // Mark as unsynced so the status change pushes to Supabase
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  // --- Harvests (Weight Entries) ---
  Future<void> insertHarvest(Map<String, dynamic> harvest) async {
    final db = await instance.database;
    await db.insert('harvests', harvest, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHarvests() async {
    final db = await instance.database;
    return await db.query('harvests', where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<List<Map<String, dynamic>>> getHarvestsByFarmerId(String farmerId) async {
    final db = await instance.database;
    return await db.query(
      'harvests', 
      where: 'farmer_id = ? AND is_correction = 0', 
      whereArgs: [farmerId],
      orderBy: 'recorded_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getHarvestsByCollectorId(String collectorId) async {
    final db = await instance.database;
    return await db.query(
      'harvests', 
      where: 'collector_id = ? AND is_correction = 0', 
      whereArgs: [collectorId],
      orderBy: 'recorded_at DESC',
    );
  }

  Future<void> markHarvestSynced(String id) async {
    final db = await instance.database;
    await db.update('harvests', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

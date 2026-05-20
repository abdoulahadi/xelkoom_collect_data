import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sentence.dart';
import '../models/user.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _dbName = 'xelkoom_offline.db';
  static const int _dbVersion = 1;

  // Database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Offline recordings table
    await db.execute('''
      CREATE TABLE offline_recordings (
        id TEXT PRIMARY KEY,
        sentence_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        duration REAL,
        created_at TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    // Cached sentences table
    await db.execute('''
      CREATE TABLE cached_sentences (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        language TEXT DEFAULT 'wo',
        difficulty_level TEXT DEFAULT 'easy',
        status TEXT DEFAULT 'available',
        cached_at TEXT NOT NULL
      )
    ''');

    // User stats cache
    await db.execute('''
      CREATE TABLE cached_user_stats (
        user_id TEXT PRIMARY KEY,
        total_recordings INTEGER DEFAULT 0,
        validated_recordings INTEGER DEFAULT 0,
        rejected_recordings INTEGER DEFAULT 0,
        pending_recordings INTEGER DEFAULT 0,
        total_duration REAL DEFAULT 0.0,
        rank INTEGER DEFAULT 0,
        points INTEGER DEFAULT 0,
        last_updated TEXT NOT NULL
      )
    ''');

    // App settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database migrations
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Offline recordings management
  Future<String> saveOfflineRecording({
    required String sentenceId,
    required String userId,
    required String filePath,
    required double duration,
  }) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('offline_recordings', {
      'id': id,
      'sentence_id': sentenceId,
      'user_id': userId,
      'file_path': filePath,
      'duration': duration,
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
      'retry_count': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return id;
  }

  Future<List<Map<String, dynamic>>> getPendingRecordings() async {
    final db = await database;
    return await db.query(
      'offline_recordings',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markRecordingAsSynced(String id) async {
    final db = await database;
    await db.update(
      'offline_recordings',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markRecordingAsFailed(String id, String errorMessage) async {
    final db = await database;
    final recording = await db.query(
      'offline_recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (recording.isNotEmpty) {
      final retryCount = (recording.first['retry_count'] as int? ?? 0) + 1;
      await db.update(
        'offline_recordings',
        {
          'sync_status': retryCount >= 3 ? 'failed' : 'pending',
          'retry_count': retryCount,
          'error_message': errorMessage,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // Cached sentences management
  Future<void> cacheSentences(List<Sentence> sentences) async {
    final db = await database;
    final batch = db.batch();

    for (final sentence in sentences) {
      batch.insert('cached_sentences', {
        'id': sentence.id,
        'text': sentence.text,
        'language': sentence.language,
        'difficulty_level': sentence.difficultyLevel,
        'status': sentence.status,
        'cached_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<Sentence>> getCachedSentences({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'cached_sentences',
      where: 'status = ?',
      whereArgs: ['available'],
      limit: limit,
      orderBy: 'cached_at DESC',
    );

    return maps.map((map) => Sentence.fromJson(map)).toList();
  }

  Future<Sentence?> getNextCachedSentence() async {
    final sentences = await getCachedSentences(limit: 1);
    return sentences.isNotEmpty ? sentences.first : null;
  }

  // User stats cache
  Future<void> cacheUserStats(String userId, UserStats stats) async {
    final db = await database;
    await db.insert('cached_user_stats', {
      'user_id': userId,
      'total_recordings': stats.totalRecordings,
      'validated_recordings': stats.validatedRecordings,
      'rejected_recordings': stats.rejectedRecordings,
      'pending_recordings': stats.pendingRecordings,
      'total_duration': stats.totalDuration,
      'rank': 0, // Default value for now
      'points': 0, // Default value for now
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserStats?> getCachedUserStats(String userId) async {
    final db = await database;
    final maps = await db.query(
      'cached_user_stats',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return UserStats(
      totalRecordings: map['total_recordings'] as int,
      validatedRecordings: map['validated_recordings'] as int,
      rejectedRecordings: map['rejected_recordings'] as int,
      pendingRecordings: map['pending_recordings'] as int,
      totalDuration: map['total_duration'] as double,
    );
  }

  // App settings
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    return maps.isNotEmpty ? maps.first['value'] as String? : null;
  }

  // Cleanup old data
  Future<void> cleanupOldData() async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    // Remove old cached sentences
    await db.delete(
      'cached_sentences',
      where: 'cached_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );

    // Remove old synced recordings
    await db.delete(
      'offline_recordings',
      where: 'sync_status = ? AND created_at < ?',
      whereArgs: ['synced', cutoffDate.toIso8601String()],
    );
  }

  // Database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final pendingRecordings = await db.query(
      'offline_recordings',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );

    final cachedSentences = await db.query('cached_sentences');
    final failedRecordings = await db.query(
      'offline_recordings',
      where: 'sync_status = ?',
      whereArgs: ['failed'],
    );

    return {
      'pending_recordings': pendingRecordings.length,
      'cached_sentences': cachedSentences.length,
      'failed_recordings': failedRecordings.length,
    };
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

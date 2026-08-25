import 'package:drift/native.dart';
import 'package:ede/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3lib;

/// Hand-built v1 schema: the four original tables, `speech_attempts` WITHOUT
/// the `skipped`/`skip_reason` columns that v2 added, and no
/// `audio_cache_entries` table. Used to prove the real MigrationStrategy in
/// AppDatabase — not a reimplementation of it — actually upgrades a database
/// that predates both the v2 and the v3 change.
void _createV1Schema(sqlite3lib.Database raw) {
  raw.execute('''
    CREATE TABLE preferences (
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      PRIMARY KEY (key)
    );
    CREATE TABLE lesson_progress_rows (
      lesson_id TEXT NOT NULL,
      state TEXT NOT NULL DEFAULT 'not_started',
      furthest_block INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (lesson_id)
    );
    CREATE TABLE attempts (
      attempt_id TEXT NOT NULL,
      exercise_id TEXT NOT NULL,
      session_id TEXT NOT NULL,
      answer TEXT NOT NULL,
      is_correct INTEGER,
      feedback_json TEXT,
      synced INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (attempt_id)
    );
    CREATE TABLE speech_attempts (
      submission_id TEXT NOT NULL,
      exercise_id TEXT NOT NULL,
      session_id TEXT NOT NULL,
      audio_path TEXT,
      duration_ms INTEGER,
      synced INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (submission_id)
    );
    CREATE TABLE stats (
      id INTEGER NOT NULL DEFAULT 1,
      lessons_completed INTEGER NOT NULL DEFAULT 0,
      total_minutes INTEGER NOT NULL DEFAULT 0,
      current_streak INTEGER NOT NULL DEFAULT 0,
      xp INTEGER NOT NULL DEFAULT 0,
      words_mastered INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (id)
    );
  ''');
}

/// v2 adds exactly the two columns AppDatabase's `if (from < 2)` branch adds.
void _upgradeToV2Schema(sqlite3lib.Database raw) {
  raw.execute('''
    ALTER TABLE speech_attempts ADD COLUMN skipped INTEGER NOT NULL DEFAULT 0;
    ALTER TABLE speech_attempts ADD COLUMN skip_reason TEXT;
  ''');
}

AppDatabase _openAtVersion(int version) {
  final raw = sqlite3lib.sqlite3.openInMemory();
  _createV1Schema(raw);
  if (version >= 2) _upgradeToV2Schema(raw);
  raw.execute('PRAGMA user_version = $version;');
  return AppDatabase(NativeDatabase.opened(raw));
}

Future<List<String>> _tableNames(AppDatabase db) => db
    .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
    .map((row) => row.read<String>('name'))
    .get();

Future<List<String>> _columnNames(AppDatabase db, String table) => db
    .customSelect("PRAGMA table_info('$table')")
    .map((row) => row.read<String>('name'))
    .get();

void main() {
  group('AppDatabase migration to schema v3', () {
    test('from v1: both the v2 columns and the v3 table are created', () async {
      final db = _openAtVersion(1);
      addTearDown(db.close);

      // Any query forces drift to open the connection and run migrations.
      expect(await db.audioCacheEntry('probe'), isNull);

      expect(await _tableNames(db), contains('audio_cache_entries'));
      expect(await _columnNames(db, 'speech_attempts'),
          containsAll(['skipped', 'skip_reason']));
    });

    test('from v2: only the v3 table is created (v2 columns already exist)',
        () async {
      final db = _openAtVersion(2);
      addTearDown(db.close);

      expect(await db.audioCacheEntry('probe'), isNull);

      expect(await _tableNames(db), contains('audio_cache_entries'));
      expect(await _columnNames(db, 'speech_attempts'),
          containsAll(['skipped', 'skip_reason']));
    });

    test('a fresh (onCreate) database also has the v3 table', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      expect(await db.audioCacheEntry('probe'), isNull);
      expect(await _tableNames(db), contains('audio_cache_entries'));
    });

    test('upsert then lookup round-trips through the real table', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await db.upsertAudioCacheEntry(
        cacheKey: 'es-es-default::normal::Hola',
        source: 'tts',
        assetPath: null,
        bytes: null,
      );

      final row = await db.audioCacheEntry('es-es-default::normal::Hola');
      expect(row, isNotNull);
      expect(row!.source, 'tts');
    });
  });
}

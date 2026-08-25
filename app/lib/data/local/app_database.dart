import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../domain/entities.dart' show nextFurthestBlock;
import 'db_connection/db_connection.dart';

part 'app_database.g.dart'; // run: dart run build_runner build

/// Local persistence for this slice.
///
/// Drift (SQLite) rather than a key-value store because two of the four tables
/// are genuinely relational and one is a sync outbox that needs transactional
/// integrity. Attempts and recordings are written locally FIRST, each with a
/// client-generated idempotency key, then pushed — which is what makes an
/// offline retry free instead of a double-count, exactly as
/// `assess.attempt_idempotency` does server-side.
///
/// `isCorrect` here is a CACHE of the grader's verdict, never a recomputation.
/// In Supabase mode it is whatever `assess.submit_attempt()` returned; in local
/// mode it is the single dev mirror in `answer_matcher.dart`. The UI reads this
/// column and never re-grades, so the display can never disagree with the
/// authority.
@DataClassName('PreferenceRow')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('ProgressRow')
class LessonProgressRows extends Table {
  TextColumn get lessonId => text()();
  TextColumn get state =>
      text().withDefault(const Constant('not_started'))();
  IntColumn get furthestBlock => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {lessonId};
}

@DataClassName('AttemptRow')
class Attempts extends Table {
  TextColumn get attemptId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get sessionId => text()();
  TextColumn get answer => text()();
  BoolColumn get isCorrect => boolean().nullable()();

  /// The grader's full nine-part payload, stored verbatim so a replay returns
  /// byte-identical feedback rather than a re-derived approximation.
  TextColumn get feedbackJson => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {attemptId};
}

@DataClassName('SpeechRow')
class SpeechAttempts extends Table {
  TextColumn get submissionId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get sessionId => text()();
  TextColumn get audioPath => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// A skip is stored in the same table but is never successful evidence: it
  /// carries no audio, no duration, and is filtered out of every query that
  /// answers "did the learner submit this speech exercise".
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get skipReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {submissionId};
}

/// Local mirror of `learning.learner_stats`. In Supabase mode the server row is
/// authoritative and this is only a cache: XP is server-computed and the client
/// has no write grant on it.
@DataClassName('StatsRow')
class Stats extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get lessonsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get totalMinutes => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get wordsMastered => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local metadata cache for resolved audio (see domain/audio/). Additive-only:
/// storing bytes here is a cache of what a TtsProvider already returned, never
/// itself a source of truth, and dropping the whole table would only cost a
/// future re-synthesis, never any user data.
@DataClassName('AudioCacheRow')
class AudioCacheEntries extends Table {
  /// AudioIdentity.cacheKey — deterministic, so this is a natural primary key.
  TextColumn get cacheKey => text()();

  /// AudioSource.wire of the resolution that was cached. In practice this is
  /// always 'tts': see DriftAudioCache.store for why human overrides and
  /// cache hits are never re-written here.
  TextColumn get source => text()();
  TextColumn get assetPath => text().nullable()();
  BlobColumn get bytes => blob().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

@DriftDatabase(
  tables: [
    Preferences,
    LessonProgressRows,
    Attempts,
    SpeechAttempts,
    Stats,
    AudioCacheEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// On-disk (native) / OPFS-backed (web) database for the running app. Which
  /// one it actually is gets picked at compile time — see
  /// db_connection/db_connection.dart — so this class itself never imports
  /// dart:io or a platform-specific drift backend directly.
  factory AppDatabase.file() => AppDatabase(openConnection());

  /// In-memory database for widget and unit tests: no file system, no plugins.
  factory AppDatabase.memory() => AppDatabase(openMemoryConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Each `if` is independent and additive, not `else if`: a learner
          // upgrading straight from v1 must get BOTH the v2 columns and the
          // v3 table in one pass, exactly as if they had stopped at v2 first.
          if (from < 2) {
            await m.addColumn(speechAttempts, speechAttempts.skipped);
            await m.addColumn(speechAttempts, speechAttempts.skipReason);
          }
          if (from < 3) {
            await m.createTable(audioCacheEntries);
          }
        },
      );

  // -------------------------------------------------------------- audio cache

  Future<AudioCacheRow?> audioCacheEntry(String cacheKey) =>
      (select(audioCacheEntries)..where((t) => t.cacheKey.equals(cacheKey)))
          .getSingleOrNull();

  Future<void> upsertAudioCacheEntry({
    required String cacheKey,
    required String source,
    String? assetPath,
    Uint8List? bytes,
  }) =>
      into(audioCacheEntries).insertOnConflictUpdate(AudioCacheRow(
        cacheKey: cacheKey,
        source: source,
        assetPath: assetPath,
        bytes: bytes,
        createdAt: DateTime.now(),
      ));

  // ------------------------------------------------------------ preferences --

  Future<Map<String, String>> allPreferences() async {
    final rows = await select(preferences).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> setPreference(String key, String value) =>
      into(preferences).insertOnConflictUpdate(
        PreferenceRow(key: key, value: value),
      );

  // --------------------------------------------------------------- progress --

  Future<List<ProgressRow>> allProgress() => select(lessonProgressRows).get();

  Future<ProgressRow?> progressFor(String lessonId) =>
      (select(lessonProgressRows)
            ..where((t) => t.lessonId.equals(lessonId)))
          .getSingleOrNull();

  Future<void> upsertProgress(
    String lessonId,
    String state,
    int furthestBlock,
  ) =>
      into(lessonProgressRows).insertOnConflictUpdate(
        ProgressRow(
          lessonId: lessonId,
          state: state,
          furthestBlock: furthestBlock,
          updatedAt: DateTime.now(),
        ),
      );

  /// Read-compare-write, so it MUST run inside a transaction: two overlapping
  /// calls (e.g. several blocks crediting in the same frame) would otherwise
  /// both read the same stale `furthestBlock`, and whichever write lands last
  /// would silently overwrite a higher value with a lower one. `transaction()`
  /// serializes concurrent calls on this database, closing that race.
  Future<void> markBlockViewed(String lessonId, int blockIndex) =>
      transaction(() async {
        final existing = await progressFor(lessonId);
        if (existing?.state == 'completed') return; // never regress a completion
        final furthest =
            nextFurthestBlock(current: existing?.furthestBlock ?? 0, reached: blockIndex);
        await upsertProgress(lessonId, 'in_progress', furthest);
      });

  // --------------------------------------------------------------- attempts --

  Future<AttemptRow?> attemptById(String attemptId) =>
      (select(attempts)..where((t) => t.attemptId.equals(attemptId)))
          .getSingleOrNull();

  Future<void> saveAttempt(AttemptRow row) =>
      into(attempts).insertOnConflictUpdate(row);

  Future<List<String>> correctExerciseIds() async {
    final rows =
        await (select(attempts)..where((t) => t.isCorrect.equals(true))).get();
    return rows.map((r) => r.exerciseId).toSet().toList();
  }

  /// Outbox drain: everything not yet acknowledged by the server.
  Future<List<AttemptRow>> unsyncedAttempts() =>
      (select(attempts)..where((t) => t.synced.equals(false))).get();

  Future<void> markAttemptSynced(String attemptId) =>
      (update(attempts)..where((t) => t.attemptId.equals(attemptId)))
          .write(const AttemptsCompanion(synced: Value(true)));

  // ----------------------------------------------------------------- speech --

  Future<void> saveSpeech(SpeechRow row) =>
      into(speechAttempts).insertOnConflictUpdate(row);

  /// Successful evidence only. A skipped attempt (see [skippedSpeechExerciseIds])
  /// is deliberately excluded — it must never be able to satisfy a required
  /// speech exercise.
  Future<List<String>> speechExerciseIds() async {
    final rows =
        await (select(speechAttempts)..where((t) => t.skipped.equals(false))).get();
    return rows.map((r) => r.exerciseId).toSet().toList();
  }

  Future<List<String>> skippedSpeechExerciseIds() async {
    final rows =
        await (select(speechAttempts)..where((t) => t.skipped.equals(true))).get();
    return rows.map((r) => r.exerciseId).toSet().toList();
  }

  Future<List<SpeechRow>> unsyncedSpeech() =>
      (select(speechAttempts)..where((t) => t.synced.equals(false))).get();

  // ------------------------------------------------------------------ stats --

  Future<StatsRow> statsRow() async {
    final existing =
        await (select(stats)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    const fresh = StatsRow(
      id: 1,
      lessonsCompleted: 0,
      totalMinutes: 0,
      currentStreak: 0,
      xp: 0,
      wordsMastered: 0,
    );
    await into(stats).insertOnConflictUpdate(fresh);
    return fresh;
  }

  Future<void> writeStats(StatsRow row) =>
      into(stats).insertOnConflictUpdate(row.copyWith(id: 1));
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

@DriftDatabase(
  tables: [Preferences, LessonProgressRows, Attempts, SpeechAttempts, Stats],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// On-disk database for the running app.
  factory AppDatabase.file() {
    return AppDatabase(
      LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        return NativeDatabase.createInBackground(
          File(p.join(dir.path, 'ede.sqlite')),
        );
      }),
    );
  }

  /// In-memory database for widget and unit tests: no file system, no plugins.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

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

  Future<List<String>> speechExerciseIds() async {
    final rows = await select(speechAttempts).get();
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

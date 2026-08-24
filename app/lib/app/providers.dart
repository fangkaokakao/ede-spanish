import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/app_database.dart';
import '../data/repositories/local_repositories.dart';
import '../data/repositories/speech_repository_impl.dart';
import '../data/repositories/supabase_repositories.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import 'env.dart';

/// One place decides which data source the app runs against. No widget and no
/// controller ever knows which one it got — that is what lets the whole slice
/// run with no backend and switch to Supabase without touching UI code.
enum DataSource { local, supabase }

final dataSourceProvider = Provider<DataSource>(
  (_) => Env.isConfigured ? DataSource.supabase : DataSource.local,
);

/// Overridden in main() with the opened database, and in tests with an
/// in-memory one (see test/widget/harness.dart).
final databaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('override databaseProvider in main() or tests'),
);

// ------------------------------------------------------------- repositories --

/// The pack is the read model in BOTH modes: published curriculum is served as
/// an immutable versioned pack, never assembled row-by-row at runtime.
final curriculumRepositoryProvider =
    Provider<CurriculumRepository>((ref) => PackCurriculumRepository());

final grammarRepositoryProvider = Provider<GrammarRepository>(
  (ref) => PackGrammarRepository(
    curriculum: ref.watch(curriculumRepositoryProvider),
  ),
);

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final curriculum = ref.watch(curriculumRepositoryProvider);
  return switch (ref.watch(dataSourceProvider)) {
    DataSource.local => LocalAttemptRepository(db, curriculum),
    DataSource.supabase =>
      SupabaseAttemptRepository(Supabase.instance.client, db),
  };
});

final speechRepositoryProvider = Provider<SpeechRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return switch (ref.watch(dataSourceProvider)) {
    // Device recorder in both modes; Supabase mode wraps it so the recording
    // is kept locally first and the submission RPC is called on top.
    DataSource.local => DeviceSpeechRepository(db),
    DataSource.supabase => SupabaseSpeechRepository(
        Supabase.instance.client, DeviceSpeechRepository(db)),
  };
});

final learnerRepositoryProvider = Provider<LearnerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return switch (ref.watch(dataSourceProvider)) {
    DataSource.local => LocalLearnerRepository(
        db,
        ref.watch(curriculumRepositoryProvider),
        ref.watch(attemptRepositoryProvider),
        ref.watch(speechRepositoryProvider),
      ),
    DataSource.supabase =>
      SupabaseLearnerRepository(Supabase.instance.client, db),
  };
});

/// Plays the model audio for an example or a pronunciation target. Kept behind
/// a provider so widget tests get a silent fake instead of a platform plugin.
final modelAudioProvider =
    Provider<ModelAudioPlayer>((ref) => ModelAudioPlayer());

// -------------------------------------------------------------- curriculum --

final levelsProvider =
    FutureProvider<List<CefrLevel>>((ref) => ref.watch(curriculumRepositoryProvider).levels());

final unitsProvider = FutureProvider.family<List<UnitSummary>, Cefr>(
  (ref, level) => ref.watch(curriculumRepositoryProvider).unitsForLevel(level),
);

final unitProvider = FutureProvider.family<UnitSummary, String>(
  (ref, unitId) => ref.watch(curriculumRepositoryProvider).unit(unitId),
);

final lessonProvider = FutureProvider.family<Lesson, String>(
  (ref, lessonId) => ref.watch(curriculumRepositoryProvider).lesson(lessonId),
);

final exerciseProvider = FutureProvider.family<Exercise, String>(
  (ref, exerciseId) =>
      ref.watch(curriculumRepositoryProvider).exercise(exerciseId),
);

final sensesProvider = FutureProvider.family<List<VocabSense>, List<String>>(
  (ref, ids) => ref.watch(curriculumRepositoryProvider).senses(ids),
);

// ----------------------------------------------------------------- learner --

final preferencesProvider = FutureProvider<LearnerPreferences>(
  (ref) => ref.watch(learnerRepositoryProvider).preferences(),
);

final statsProvider = FutureProvider<LearnerStats>(
  (ref) => ref.watch(learnerRepositoryProvider).stats(),
);

final progressProvider = FutureProvider<Map<String, LessonProgress>>(
  (ref) => ref.watch(learnerRepositoryProvider).progress(),
);

/// Home's whole job: what should I do next, and for how long. Deterministic and
/// local, so Home renders instantly and works offline — no model call.
final dailyPlanProvider = FutureProvider<DailyPlan>(
  (ref) => ref.watch(learnerRepositoryProvider).dailyPlan(),
);

/// Which of the lesson's completion requirements the learner has already met.
/// Invalidated whenever an exercise is graded or a recording is submitted, so
/// the finish section reflects real evidence rather than optimism.
final satisfiedProvider =
    FutureProvider<({Set<String> correct, Set<String> spoken})>((ref) async {
  final correct = await ref.watch(attemptRepositoryProvider).gradedExerciseIds();
  final spoken = await ref.watch(speechRepositoryProvider).submittedExerciseIds();
  return (correct: correct, spoken: spoken);
});

/// Opens a study session for a lesson. The session id is required by
/// `assess.submit_attempt` and `assess.submit_speech`: the server validates
/// that it belongs to the caller and is still open, which is what makes the
/// "distinct sitting" evidence for recurring errors trustworthy.
final lessonSessionProvider = FutureProvider.family<String, String>(
  (ref, lessonId) => ref
      .watch(learnerRepositoryProvider)
      .startSession(kind: 'lesson', lessonId: lessonId),
);

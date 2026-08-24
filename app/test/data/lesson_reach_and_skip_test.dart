import 'package:ede/data/local/app_database.dart';
import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/data/repositories/speech_repository_impl.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  group('reach persistence', () {
    const lessonId = 'lesson-1';

    test('a fresh lesson has no persisted progress', () async {
      expect(await db.progressFor(lessonId), isNull);
    });

    test('reaching block index 0 is persisted', () async {
      await db.markBlockViewed(lessonId, 0);
      final row = await db.progressFor(lessonId);
      expect(row!.furthestBlock, 0);
      expect(row.state, 'in_progress');
    });

    test('reaching a later block advances the persisted furthest index', () async {
      await db.markBlockViewed(lessonId, 2);
      await db.markBlockViewed(lessonId, 6);
      expect((await db.progressFor(lessonId))!.furthestBlock, 6);
    });

    test('reaching a lower block afterward never regresses the persisted index', () async {
      await db.markBlockViewed(lessonId, 6);
      await db.markBlockViewed(lessonId, 1); // e.g. learner scrolled back up
      expect((await db.progressFor(lessonId))!.furthestBlock, 6);
    });

    test('a completed lesson restores consistently and is never regressed', () async {
      await db.markBlockViewed(lessonId, 3);
      await db.upsertProgress(lessonId, 'completed', 9);

      // A stray reach event after completion (e.g. a late scroll callback)
      // must not reopen or regress the completed lesson.
      await db.markBlockViewed(lessonId, 1);

      final row = await db.progressFor(lessonId);
      expect(row!.state, 'completed');
      expect(row.furthestBlock, 9);
    });

    test('overlapping reach calls never lose the higher index (restore/reach race)', () async {
      // Several blocks crediting "at once" (e.g. built in the same frame)
      // must not race a read-modify-write and let a lower index win.
      await Future.wait([
        db.markBlockViewed(lessonId, 1),
        db.markBlockViewed(lessonId, 4),
        db.markBlockViewed(lessonId, 2),
        db.markBlockViewed(lessonId, 7),
        db.markBlockViewed(lessonId, 3),
      ]);
      expect((await db.progressFor(lessonId))!.furthestBlock, 7);
    });
  });

  group('speaking skip persistence', () {
    // A database-backed double, not DeviceSpeechRepository: constructing
    // DeviceSpeechRepository eagerly creates just_audio/record plugin
    // instances, which touch platform channels before
    // TestWidgetsFlutterBinding exists and crash a plain `flutter test` run.
    // Recording/playback are irrelevant here — only skip-vs-submit storage is
    // under test — so TestSpeechRepository exercises the identical
    // AppDatabase-backed persistence without ever touching those plugins.
    late TestSpeechRepository speech;
    const exerciseId = 'ex-speak-1';
    const sessionId = 'session-1';

    setUp(() => speech = TestSpeechRepository(db));

    test('a skip creates no successful speaking evidence', () async {
      await speech.skipSpeech(
        submissionId: 'sub-1',
        exerciseId: exerciseId,
        sessionId: sessionId,
        reason: SkipReason.learnerChoice,
      );

      expect(await speech.submittedExerciseIds(), isNot(contains(exerciseId)));
      expect(await speech.skippedExerciseIds(), contains(exerciseId));
    });

    test('a real submission is never shadowed by an unrelated skip', () async {
      await speech.submitSpeech(
        submissionId: 'sub-2',
        exerciseId: exerciseId,
        sessionId: sessionId,
        audioPath: '/tmp/rec.m4a',
        durationMs: 1200,
      );

      expect(await speech.submittedExerciseIds(), contains(exerciseId));
      expect(await speech.skippedExerciseIds(), isNot(contains(exerciseId)));
    });

    test('an asrInconclusive skip is stored as a skip, never as incorrect evidence', () async {
      await speech.skipSpeech(
        submissionId: 'sub-3',
        exerciseId: exerciseId,
        sessionId: sessionId,
        reason: SkipReason.asrInconclusive,
      );

      // No score/verdict field exists on speaking evidence at all in this
      // slice, so "never treated as incorrect" reduces to: it is a skip, not
      // success evidence, and nothing else reads it as a grade.
      expect(await speech.skippedExerciseIds(), contains(exerciseId));
      expect(await speech.submittedExerciseIds(), isEmpty);
    });
  });

  group('completeLesson (local mirror) respects reach and skip semantics', () {
    // Mirrors the authored Pre-A1 lesson fixture: 2 required correct
    // exercises, 1 required speech exercise, min_blocks_viewed: 7.
    const lessonId = '44444444-4444-4444-8444-444444444403';
    const requiredCorrect1 = '66666666-6666-4666-8666-666666666601';
    const requiredCorrect2 = '66666666-6666-4666-8666-666666666602';
    const requiredSpeech = '66666666-6666-4666-8666-666666666603';

    late PackCurriculumRepository curriculum;
    late LocalAttemptRepository attempts;
    late TestSpeechRepository speech;
    late LocalLearnerRepository learner;

    setUp(() {
      curriculum = PackCurriculumRepository();
      attempts = LocalAttemptRepository(db, curriculum);
      speech = TestSpeechRepository(db);
      learner = LocalLearnerRepository(db, curriculum, attempts, speech);
    });

    test('a required speaking skip blocks completion', () async {
      // Reach + both required correct exercises satisfied; only the required
      // speech exercise is skipped rather than submitted — isolating skip as
      // the sole reason completion is refused.
      await db.markBlockViewed(lessonId, 8);
      await attempts.submit(
        attemptId: '11111111-0000-4000-8000-000000000001',
        exerciseId: requiredCorrect1,
        answer: 'Me llamo Somchai',
        sessionId: 's1',
      );
      await attempts.submit(
        attemptId: '11111111-0000-4000-8000-000000000002',
        exerciseId: requiredCorrect2,
        answer: '¿Cómo os llamáis?',
        sessionId: 's1',
      );
      await speech.skipSpeech(
        submissionId: 'skip-1',
        exerciseId: requiredSpeech,
        sessionId: 's1',
        reason: SkipReason.permissionDenied,
      );

      final res = await learner.completeLesson(lessonId);
      expect(res.completed, isFalse);
      expect(res.missing, ['speech:$requiredSpeech']);
    });

    test('lesson completion respects minBlocksViewed even with all evidence present', () async {
      await db.markBlockViewed(lessonId, 2); // fewer than min_blocks_viewed: 7
      await speech.submitSpeech(
        submissionId: 'sub-1',
        exerciseId: requiredSpeech,
        sessionId: 's1',
      );

      final res = await learner.completeLesson(lessonId);
      expect(res.completed, isFalse);
      expect(res.missing, contains('blocks_viewed'));
    });
  });
}

import 'entities.dart';

/// Repository interfaces. The UI depends only on these, so the same widgets run
/// against the local pack (no network) and against Supabase.
abstract interface class CurriculumRepository {
  Future<List<CefrLevel>> levels();
  Future<List<UnitSummary>> unitsForLevel(Cefr level);
  Future<UnitSummary> unit(String unitId);
  Future<Lesson> lesson(String lessonId);
  Future<Exercise> exercise(String exerciseId);
  Future<List<VocabSense>> senses(List<String> senseIds);
}

abstract interface class LearnerRepository {
  Future<LearnerPreferences> preferences();
  Future<void> savePreferences(LearnerPreferences prefs);

  Future<LearnerStats> stats();
  Future<Map<String, LessonProgress>> progress();
  Future<void> markBlockViewed(String lessonId, int blockIndex);

  /// Server-authoritative. Returns what is still missing when refused.
  Future<CompletionResult> completeLesson(String lessonId);

  Future<DailyPlan> dailyPlan();

  /// A study session is server-created; the client asks for one and never
  /// asserts one. Returns the session id required by attempt submission.
  Future<String> startSession({required String kind, String? lessonId});
  Future<void> endSession(String sessionId);
}

abstract interface class AttemptRepository {
  /// [attemptId] is client-generated and is the idempotency key: a retry after
  /// a dropped connection returns the identical stored verdict and creates no
  /// second attempt, no second mastery evidence and no second error record.
  Future<AttemptFeedback> submit({
    required String attemptId,
    required String exerciseId,
    required String answer,
    required String sessionId,
    int? latencyMs,
  });

  /// Attempt ids already graded in this run, so the UI can restore feedback
  /// without re-submitting.
  Future<Set<String>> gradedExerciseIds();
}

/// Recording only. There is no pronunciation score anywhere in this slice,
/// because no ASR or assessment provider is connected yet.
abstract interface class SpeechRepository {
  Future<bool> hasPermission();
  Future<void> startRecording(String filePath);

  /// Returns the local file path of the finished recording.
  Future<String?> stopRecording();
  Future<void> playback(String filePath);
  Future<void> stopPlayback();

  /// Registers that the learner did the speaking task. Satisfies the lesson's
  /// speech requirement; carries no verdict and no score.
  Future<void> submitSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    String? audioPath,
    int? durationMs,
  });

  Future<Set<String>> submittedExerciseIds();
}

abstract interface class GrammarRepository {
  /// Tier 0: resolves the pre-authored answer that shipped with the pack.
  /// Never touches the network, so it works offline and costs nothing.
  Future<WhyAnswer?> whyForBlock(String blockId);

  /// Tier 1/2: authored L2/L3 for a concept. Still local — these are curriculum
  /// content, not generated text.
  Future<WhyAnswer?> depth(String conceptId, WhyDepth depth);

  /// Tier 3: would call the AI gateway. Not connected in this slice; the
  /// implementation returns an explicitly labelled development stub so nothing
  /// fake is ever presented as a real tutor answer.
  Future<WhyAnswer> askTutor({
    required String questionTh,
    String? conceptId,
    String? sentenceEs,
  });
}

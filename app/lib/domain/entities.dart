// Pure Dart. No Flutter imports anywhere in domain/ — so every rule in here is
// unit-testable without a widget tester.
import 'package:collection/collection.dart';

enum Cefr { preA1, a1, a2, b1, b2, c1, c2 }

extension CefrX on Cefr {
  String get wire => switch (this) {
        Cefr.preA1 => 'pre_a1',
        Cefr.a1 => 'a1',
        Cefr.a2 => 'a2',
        Cefr.b1 => 'b1',
        Cefr.b2 => 'b2',
        Cefr.c1 => 'c1',
        Cefr.c2 => 'c2',
      };
  String get label => this == Cefr.preA1 ? 'Pre-A1' : wire.toUpperCase();
  static Cefr parse(String s) =>
      Cefr.values.firstWhere((c) => c.wire == s, orElse: () => Cefr.preA1);
}

// ---------------------------------------------------------------- curriculum --

class CefrLevel {
  const CefrLevel({
    required this.level,
    required this.nameTh,
    required this.taglineTh,
    required this.isAvailable,
  });
  final Cefr level;
  final String nameTh;
  final String taglineTh;

  /// Levels with no QA-complete curriculum are visible but not enterable.
  final bool isAvailable;
}

class UnitSummary {
  const UnitSummary({
    required this.id,
    required this.slug,
    required this.titleTh,
    required this.titleEs,
    required this.subtitleTh,
    required this.level,
    required this.lessons,
  });
  final String id, slug, titleTh, subtitleTh;
  final String? titleEs;
  final Cefr level;
  final List<LessonSummary> lessons;
}

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.slug,
    required this.titleTh,
    required this.estimatedMinutes,
    required this.sortOrder,
  });
  final String id, slug, titleTh;
  final int estimatedMinutes, sortOrder;
}

/// Server-verified completion contract, authored per lesson (see
/// content.lesson_versions.completion_rules). Mirrored here only to *show* the
/// learner what is outstanding — the grant itself is decided by
/// learning.complete_lesson().
class CompletionRules {
  const CompletionRules({
    this.requiredCorrectExercises = const [],
    this.requiredSpeechExercises = const [],
    this.minBlocksViewed = 0,
  });

  final List<String> requiredCorrectExercises;
  final List<String> requiredSpeechExercises;
  final int minBlocksViewed;

  bool get isEmpty =>
      requiredCorrectExercises.isEmpty &&
      requiredSpeechExercises.isEmpty &&
      minBlocksViewed == 0;

  factory CompletionRules.fromJson(Map<String, dynamic> j) => CompletionRules(
        requiredCorrectExercises:
            (j['required_correct_exercises'] as List? ?? const []).cast<String>(),
        requiredSpeechExercises:
            (j['required_speech_exercises'] as List? ?? const []).cast<String>(),
        minBlocksViewed: (j['min_blocks_viewed'] as int?) ?? 0,
      );

  /// The single source of truth for "is this lesson done". Used by the local
  /// mirror of learning.complete_lesson() AND by the finish-section UI, so the
  /// two can never disagree about what is still outstanding.
  ///
  /// [blocksViewed] is a COUNT (furthest block index reached + 1), not an
  /// index — a learner who has reached index 0 has viewed 1 block.
  ///
  /// A speech exercise that was only skipped (see SkipReason) must never
  /// appear in [spokenExerciseIds]: skip evidence and success evidence are
  /// stored separately, so an optional skip is silently ignored here and a
  /// required skip surfaces as missing, exactly like never having attempted it.
  List<String> missingFor({
    required Set<String> correctExerciseIds,
    required Set<String> spokenExerciseIds,
    required int blocksViewed,
  }) =>
      [
        for (final id in requiredCorrectExercises)
          if (!correctExerciseIds.contains(id)) 'correct:$id',
        for (final id in requiredSpeechExercises)
          if (!spokenExerciseIds.contains(id)) 'speech:$id',
        if (blocksViewed < minBlocksViewed) 'blocks_viewed',
      ];

  bool isSatisfiedBy({
    required Set<String> correctExerciseIds,
    required Set<String> spokenExerciseIds,
    required int blocksViewed,
  }) =>
      missingFor(
        correctExerciseIds: correctExerciseIds,
        spokenExerciseIds: spokenExerciseIds,
        blocksViewed: blocksViewed,
      ).isEmpty;
}

/// The furthest block a learner has actually reached never regresses: reaching
/// a lower index later (e.g. scrolling back up) must not shrink the saved
/// value. Centralized here so neither the UI nor the persistence layer
/// reimplements this comparison.
int nextFurthestBlock({required int current, required int reached}) =>
    reached > current ? reached : current;

/// Why a required or optional speaking block has no successful evidence.
/// Stored separately from a successful [SpeechRepository.submitSpeech] — a
/// skip is never treated as, and never produces, speaking evidence.
enum SkipReason {
  permissionDenied,
  unsupportedPlatform,
  recorderFailed,
  learnerChoice,
  asrInconclusive,
}

extension SkipReasonX on SkipReason {
  String get wire => switch (this) {
        SkipReason.permissionDenied => 'permission_denied',
        SkipReason.unsupportedPlatform => 'unsupported_platform',
        SkipReason.recorderFailed => 'recorder_failed',
        SkipReason.learnerChoice => 'learner_choice',
        SkipReason.asrInconclusive => 'asr_inconclusive',
      };

  static SkipReason parse(String s) => SkipReason.values
      .firstWhere((r) => r.wire == s, orElse: () => SkipReason.learnerChoice);
}

class Lesson {
  const Lesson({
    required this.id,
    required this.versionId,
    required this.slug,
    required this.titleTh,
    required this.titleEs,
    required this.goalTh,
    required this.estimatedMinutes,
    required this.blocks,
    required this.completionRules,
  });
  final String id, versionId, slug, titleTh, goalTh;
  final String? titleEs;
  final int estimatedMinutes;
  final List<ContentBlock> blocks;
  final CompletionRules completionRules;
}

// -------------------------------------------------------------- audio + IPA --

class AudioRef {
  const AudioRef({this.normal, this.slow});
  final String? normal;
  final String? slow;
  bool get hasAny => normal != null || slow != null;

  factory AudioRef.fromJson(Map<String, dynamic>? j) => j == null
      ? const AudioRef()
      : AudioRef(normal: j['normal'] as String?, slow: j['slow'] as String?);
}

/// One token of a Spanish sentence, with its grammatical role and (optionally)
/// its morphological segmentation for the analysis view.
class Token {
  const Token({required this.text, this.role, this.segments = const []});
  final String text;
  final String? role;
  final List<MorphSegment> segments;

  factory Token.fromJson(Map<String, dynamic> j) => Token(
        text: j['t'] as String,
        role: j['role'] as String?,
        segments: (j['segments'] as List? ?? const [])
            .map((e) => MorphSegment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MorphSegment {
  const MorphSegment({required this.text, required this.glossTh});
  final String text, glossTh;
  factory MorphSegment.fromJson(Map<String, dynamic> j) =>
      MorphSegment(text: j['s'] as String, glossTh: j['th'] as String);
}

// ------------------------------------------------------------ content blocks --

/// Sealed so the renderer registry is exhaustive at compile time: adding a
/// block type to the schema forces the renderer to handle it.
sealed class ContentBlock {
  const ContentBlock({
    required this.id,
    required this.sortOrder,
    this.conceptId,
    this.whyL1Th,
  });

  final String id;
  final int sortOrder;
  final String? conceptId;

  /// Pre-authored instant "ทำไม?" answer. Ships inside the pack: zero cost,
  /// works offline, and is the reason >=70% of Why taps never call a model.
  final String? whyL1Th;

  bool get hasWhy => whyL1Th != null && whyL1Th!.trim().isNotEmpty;

  static ContentBlock fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final order = j['sort_order'] as int;
    final concept = j['concept_id'] as String?;
    final why = j['why_l1_th'] as String?;
    final p = (j['payload'] as Map).cast<String, dynamic>();

    return switch (j['block_type'] as String) {
      'heading' => HeadingBlock(
          id: id, sortOrder: order, textTh: p['th'] as String),
      'text' || 'explanation' => ExplanationBlock(
          id: id,
          sortOrder: order,
          conceptId: concept,
          whyL1Th: why,
          titleTh: p['title_th'] as String?,
          bodyTh: p['th'] as String,
        ),
      'example' => ExampleBlock(
          id: id,
          sortOrder: order,
          conceptId: concept,
          whyL1Th: why,
          es: p['es'] as String,
          th: p['th'] as String,
          literalTh: p['literal_th'] as String?,
          naturalNoteTh: p['natural_note_th'] as String?,
          audio: AudioRef.fromJson((p['audio'] as Map?)?.cast<String, dynamic>()),
          tokens: (p['tokens'] as List? ?? const [])
              .map((e) => Token.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        ),
      'pronunciation_guide' => PronunciationBlock(
          id: id,
          sortOrder: order,
          conceptId: concept,
          whyL1Th: why,
          targetSlug: p['target_slug'] as String,
          focus: p['focus'] as String,
          ipaPhonemic: p['ipa_phonemic'] as String?,
          ipaPhonetic: p['ipa_phonetic'] as String?,
          noteTh: p['note_th'] as String,
          contrastA: (p['contrast_pair'] as Map?)?['a'] as String?,
          contrastB: (p['contrast_pair'] as Map?)?['b'] as String?,
          contrastNoteTh: (p['contrast_pair'] as Map?)?['note_th'] as String?,
          audio: AudioRef.fromJson((p['audio'] as Map?)?.cast<String, dynamic>()),
        ),
      'comparison' => ComparisonBlock(
          id: id,
          sortOrder: order,
          conceptId: concept,
          whyL1Th: why,
          titleTh: p['title_th'] as String,
          rows: (p['rows'] as List)
              .map((e) => ComparisonRow.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
          noteTh: p['note_th'] as String?,
        ),
      'dialogue' => DialogueBlock(
          id: id,
          sortOrder: order,
          conceptId: concept,
          whyL1Th: why,
          titleTh: p['title_th'] as String,
          turns: (p['turns'] as List)
              .map((e) => DialogueTurn.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
          noteTh: p['note_th'] as String?,
        ),
      'vocabulary' => VocabularyBlock(
          id: id,
          sortOrder: order,
          senseIds: (p['sense_ids'] as List).cast<String>(),
          titleTh: p['title_th'] as String? ?? 'คำศัพท์ในบทนี้',
        ),
      'review' => ReviewBlock(
          id: id,
          sortOrder: order,
          titleTh: p['title_th'] as String? ?? 'ทบทวน',
          pointsTh: (p['points_th'] as List).cast<String>(),
        ),
      'exercise_embed' => ExerciseEmbedBlock(
          id: id, sortOrder: order, exerciseId: p['exercise_id'] as String),
      final other => throw UnsupportedError('unknown block_type: $other'),
    };
  }
}

class HeadingBlock extends ContentBlock {
  const HeadingBlock({required super.id, required super.sortOrder, required this.textTh});
  final String textTh;
}

class ExplanationBlock extends ContentBlock {
  const ExplanationBlock({
    required super.id,
    required super.sortOrder,
    super.conceptId,
    super.whyL1Th,
    this.titleTh,
    required this.bodyTh,
  });
  final String? titleTh;
  final String bodyTh;
}

class ExampleBlock extends ContentBlock {
  const ExampleBlock({
    required super.id,
    required super.sortOrder,
    super.conceptId,
    super.whyL1Th,
    required this.es,
    required this.th,
    this.literalTh,
    this.naturalNoteTh,
    this.audio = const AudioRef(),
    this.tokens = const [],
  });
  final String es, th;
  final String? literalTh, naturalNoteTh;
  final AudioRef audio;
  final List<Token> tokens;
}

class PronunciationBlock extends ContentBlock {
  const PronunciationBlock({
    required super.id,
    required super.sortOrder,
    super.conceptId,
    super.whyL1Th,
    required this.targetSlug,
    required this.focus,
    this.ipaPhonemic,
    this.ipaPhonetic,
    required this.noteTh,
    this.contrastA,
    this.contrastB,
    this.contrastNoteTh,
    this.audio = const AudioRef(),
  });
  final String targetSlug, focus, noteTh;
  final String? ipaPhonemic, ipaPhonetic, contrastA, contrastB, contrastNoteTh;
  final AudioRef audio;
}

class ComparisonRow {
  const ComparisonRow({required this.labelTh, required this.es, required this.register});
  final String labelTh, es, register;
  factory ComparisonRow.fromJson(Map<String, dynamic> j) => ComparisonRow(
        labelTh: j['label_th'] as String,
        es: j['es'] as String,
        register: j['register'] as String? ?? 'neutral',
      );
}

class ComparisonBlock extends ContentBlock {
  const ComparisonBlock({
    required super.id,
    required super.sortOrder,
    super.conceptId,
    super.whyL1Th,
    required this.titleTh,
    required this.rows,
    this.noteTh,
  });
  final String titleTh;
  final List<ComparisonRow> rows;
  final String? noteTh;
}

class DialogueTurn {
  const DialogueTurn({required this.speaker, required this.es, required this.th});
  final String speaker, es, th;
  factory DialogueTurn.fromJson(Map<String, dynamic> j) => DialogueTurn(
        speaker: j['speaker'] as String,
        es: j['es'] as String,
        th: j['th'] as String,
      );
}

class DialogueBlock extends ContentBlock {
  const DialogueBlock({
    required super.id,
    required super.sortOrder,
    super.conceptId,
    super.whyL1Th,
    required this.titleTh,
    required this.turns,
    this.noteTh,
  });
  final String titleTh;
  final List<DialogueTurn> turns;
  final String? noteTh;
}

class VocabularyBlock extends ContentBlock {
  const VocabularyBlock({
    required super.id,
    required super.sortOrder,
    required this.senseIds,
    required this.titleTh,
  });
  final List<String> senseIds;
  final String titleTh;
}

class ReviewBlock extends ContentBlock {
  const ReviewBlock({
    required super.id,
    required super.sortOrder,
    required this.titleTh,
    required this.pointsTh,
  });
  final String titleTh;
  final List<String> pointsTh;
}

class ExerciseEmbedBlock extends ContentBlock {
  const ExerciseEmbedBlock({
    required super.id,
    required super.sortOrder,
    required this.exerciseId,
  });
  final String exerciseId;
}

// ----------------------------------------------------------------- exercises --

enum ExerciseKind { mcq, typed, repeatSpeech, unsupported }

class AnswerRules {
  const AnswerRules({
    this.accepted = const [],
    this.pattern,
    this.accentInsensitive = false,
    this.modelAnswer,
    this.errorCodes = const [],
    this.framePattern,
    this.minConfidence,
  });

  final List<String> accepted;
  final String? pattern;
  final bool accentInsensitive;
  final String? modelAnswer;
  final List<String> errorCodes;
  final String? framePattern;
  final double? minConfidence;

  factory AnswerRules.fromJson(Map<String, dynamic> j) => AnswerRules(
        accepted: (j['accepted'] as List? ?? const []).cast<String>(),
        pattern: j['pattern'] as String?,
        accentInsensitive: (j['accent_insensitive'] as bool?) ?? false,
        modelAnswer: j['model_answer'] as String?,
        errorCodes: (j['error_codes'] as List? ?? const []).cast<String>(),
        framePattern: j['frame_pattern'] as String?,
        minConfidence: (j['min_confidence'] as num?)?.toDouble(),
      );
}

class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.promptTh,
    required this.payload,
    required this.rules,
    required this.feedback,
    this.objectiveId,
    this.conceptId,
  });

  final String id;
  final ExerciseKind kind;
  final String promptTh;
  final Map<String, dynamic> payload;
  final AnswerRules rules;
  final Map<String, dynamic> feedback;
  final String? objectiveId, conceptId;

  List<String> get options =>
      (payload['options'] as List? ?? const []).cast<String>();
  String? get stem => payload['stem'] as String?;
  String? get hintTh => payload['hint_th'] as String?;

  /// True when the exercise has a free proper-noun slot. The name is content,
  /// not a target: it is never graded and never scored phonetically.
  bool get hasNameSlot => payload['name_slot'] == true;
  String? get scoredFrame => payload['scored_frame'] as String?;
  String? get displayEs => payload['display_es'] as String?;
  String? get focusTh => payload['focus_th'] as String?;

  factory Exercise.fromJson(Map<String, dynamic> j) {
    final p = (j['payload'] as Map).cast<String, dynamic>();
    return Exercise(
      id: j['id'] as String,
      kind: switch (j['template_id'] as String) {
        'mcq' => ExerciseKind.mcq,
        'typed' => ExerciseKind.typed,
        'repeat_speech' || 'read_aloud' => ExerciseKind.repeatSpeech,
        _ => ExerciseKind.unsupported,
      },
      promptTh: j['prompt_th'] as String? ?? '',
      payload: p,
      rules: AnswerRules.fromJson((j['answer_rules'] as Map).cast<String, dynamic>()),
      feedback: ((j['feedback'] as Map?) ?? const {}).cast<String, dynamic>(),
      objectiveId: j['objective_id'] as String?,
      conceptId: j['concept_id'] as String?,
    );
  }
}

/// Exactly the payload assess.submit_attempt() returns. The client never
/// invents any of these fields.
class AttemptFeedback {
  const AttemptFeedback({
    required this.isCorrect,
    this.yourAnswer,
    this.correct,
    this.whatChanged,
    this.whyTh,
    this.contrastEs,
    this.contrastTh,
    this.ruleConceptId,
    this.errorCodes = const [],
    this.canRetry = true,
    this.deepAvailable = false,
    this.replayed = false,
  });

  final bool isCorrect;
  final String? yourAnswer, correct, whatChanged, whyTh, contrastEs, contrastTh;
  final String? ruleConceptId;
  final List<String> errorCodes;
  final bool canRetry, deepAvailable, replayed;

  factory AttemptFeedback.fromJson(Map<String, dynamic> j) {
    final c = (j['contrast'] as Map?)?.cast<String, dynamic>();
    return AttemptFeedback(
      isCorrect: j['is_correct'] as bool,
      yourAnswer: j['your_answer'] as String?,
      correct: j['correct'] as String?,
      whatChanged: j['what_changed'] as String?,
      whyTh: j['why_th'] as String?,
      contrastEs: c?['es'] as String?,
      contrastTh: c?['th'] as String?,
      ruleConceptId: j['rule_concept'] as String?,
      errorCodes: (j['error_codes'] as List? ?? const []).cast<String>(),
      canRetry: (j['can_retry'] as bool?) ?? true,
      deepAvailable: (j['deep_available'] as bool?) ?? false,
      replayed: (j['replayed'] as bool?) ?? false,
    );
  }
}

// ------------------------------------------------------------------- grammar --

/// Progressive disclosure tiers. L4 is opt-in and never shown automatically.
enum WhyDepth { l1Simple, l2Understand, l3Deep, l4Linguistic }

class WhyAnswer {
  const WhyAnswer({
    required this.depth,
    required this.bodyTh,
    required this.source,
    this.conceptNameTh,
    this.spainNoteTh,
    this.thaiContrastTh,
    this.deeperAvailable = false,
  });

  final WhyDepth depth;
  final String bodyTh;

  /// 'pack' = pre-authored, offline, free. 'ai_stub' = development placeholder,
  /// clearly labelled in the UI and never presented as a real tutor answer.
  final String source;
  final String? conceptNameTh, spainNoteTh, thaiContrastTh;
  final bool deeperAvailable;
}

class VocabSense {
  const VocabSense({
    required this.id,
    required this.lemma,
    required this.pos,
    required this.gender,
    required this.meaningTh,
    required this.ipaPhonemic,
    required this.ipaPhonetic,
    this.pluralForm,
    this.spainNote,
    this.examples = const [],
    this.collocations = const [],
  });
  final String id, lemma, pos, meaningTh;
  final String? gender, pluralForm, spainNote, ipaPhonemic, ipaPhonetic;
  final List<({String es, String th})> examples;
  final List<({String phrase, String th})> collocations;

  String get articleHint => switch (gender) {
        'm' => 'el $lemma',
        'f' => 'la $lemma',
        _ => lemma,
      };
}

// ------------------------------------------------------------------- learner --

enum LearningGoal { liveInSpain, travel, partner, work, study, dele, interest }

extension LearningGoalX on LearningGoal {
  String get wire => switch (this) {
        LearningGoal.liveInSpain => 'live_in_spain',
        LearningGoal.travel => 'travel',
        LearningGoal.partner => 'partner',
        LearningGoal.work => 'work',
        LearningGoal.study => 'study',
        LearningGoal.dele => 'dele',
        LearningGoal.interest => 'interest',
      };
  String get labelTh => switch (this) {
        LearningGoal.liveInSpain => 'ย้ายไปอยู่สเปน',
        LearningGoal.travel => 'ไปเที่ยวสเปน',
        LearningGoal.partner => 'คุยกับคนสเปนที่รู้จัก',
        LearningGoal.work => 'ใช้ทำงาน',
        LearningGoal.study => 'ไปเรียนต่อ',
        LearningGoal.dele => 'สอบ DELE',
        LearningGoal.interest => 'สนใจภาษาสเปน',
      };
}

/// Affects only sentences that genuinely describe the learner
/// (Estoy cansado / cansada). Never alters the grammatical gender of unrelated
/// nouns, and never inferred.
enum SelfReference { masculine, feminine, both }

extension SelfReferenceX on SelfReference {
  String get wire => name;
  String get labelTh => switch (this) {
        SelfReference.masculine => 'รูปผู้ชาย (cansado)',
        SelfReference.feminine => 'รูปผู้หญิง (cansada)',
        SelfReference.both => 'แสดงทั้งสองรูป',
      };
}

class LearnerPreferences {
  const LearnerPreferences({
    this.goal,
    this.dailyGoalMinutes = 15,
    this.selfReference = SelfReference.both,
    this.hasStudiedBefore = false,
    this.onboardingComplete = false,
    this.explanationDepth = 1,
  });

  final LearningGoal? goal;
  final int dailyGoalMinutes;
  final SelfReference selfReference;
  final bool hasStudiedBefore, onboardingComplete;
  final int explanationDepth;

  LearnerPreferences copyWith({
    LearningGoal? goal,
    int? dailyGoalMinutes,
    SelfReference? selfReference,
    bool? hasStudiedBefore,
    bool? onboardingComplete,
    int? explanationDepth,
  }) =>
      LearnerPreferences(
        goal: goal ?? this.goal,
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        selfReference: selfReference ?? this.selfReference,
        hasStudiedBefore: hasStudiedBefore ?? this.hasStudiedBefore,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        explanationDepth: explanationDepth ?? this.explanationDepth,
      );
}

enum LessonState { notStarted, inProgress, completed }

class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.state,
    this.lastBlockIndex = 0,
  });
  final String lessonId;
  final LessonState state;
  final int lastBlockIndex;
}

class LearnerStats {
  const LearnerStats({
    this.lessonsCompleted = 0,
    this.totalMinutes = 0,
    this.xp = 0,
    this.currentStreak = 0,
    this.wordsMastered = 0,
  });
  final int lessonsCompleted, totalMinutes, xp, currentStreak, wordsMastered;
}

/// Result of learning.complete_lesson(). `missing` is what the learner still
/// owes; `awarded` is false on every replay.
class CompletionResult {
  const CompletionResult({
    required this.completed,
    required this.awarded,
    required this.alreadyCompleted,
    this.missing = const [],
  });
  final bool completed, awarded, alreadyCompleted;
  final List<String> missing;

  factory CompletionResult.fromJson(Map<String, dynamic> j) => CompletionResult(
        completed: j['completed'] as bool,
        awarded: j['awarded'] as bool,
        alreadyCompleted: (j['already_completed'] as bool?) ?? false,
        missing: (j['missing'] as List? ?? const []).cast<String>(),
      );
}

class PlanItem {
  const PlanItem({
    required this.kind,
    required this.labelTh,
    required this.minutes,
    this.lessonId,
    this.count,
    this.done = false,
  });
  final String kind, labelTh;
  final int minutes;
  final String? lessonId;
  final int? count;
  final bool done;
}

class DailyPlan {
  const DailyPlan({required this.budgetMinutes, required this.items});
  final int budgetMinutes;
  final List<PlanItem> items;

  PlanItem? get current => items.firstWhereOrNull((i) => !i.done);
  int get remainingMinutes =>
      items.where((i) => !i.done).fold(0, (a, b) => a + b.minutes);
}

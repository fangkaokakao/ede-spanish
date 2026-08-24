import 'dart:async';
import 'dart:convert';

import '../../domain/answer_matcher.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../local/app_database.dart';
import '../local/content_pack.dart';

/// Reads the compiled pack. Identical shape to what the CDN will serve, so
/// swapping to a downloaded pack later changes only where the JSON comes from.
class PackCurriculumRepository implements CurriculumRepository {
  PackCurriculumRepository({Map<String, dynamic>? pack})
      : _pack = pack ?? kContentPack;

  final Map<String, dynamic> _pack;

  @override
  Future<List<CefrLevel>> levels() async =>
      (_pack['levels'] as List).map((e) {
        final m = (e as Map).cast<String, dynamic>();
        return CefrLevel(
          level: CefrX.parse(m['level'] as String),
          nameTh: m['name_th'] as String,
          taglineTh: m['tagline_th'] as String,
          isAvailable: m['is_available'] as bool,
        );
      }).toList();

  @override
  Future<List<UnitSummary>> unitsForLevel(Cefr level) async =>
      (_pack['units'] as List)
          .map((e) => _unit((e as Map).cast<String, dynamic>()))
          .where((u) => u.level == level)
          .toList();

  @override
  Future<UnitSummary> unit(String unitId) async {
    final raw = (_pack['units'] as List)
        .cast<Map<Object?, Object?>>()
        .firstWhere((u) => u['id'] == unitId,
            orElse: () => throw StateError('unit $unitId not in pack'));
    return _unit(raw.cast<String, dynamic>());
  }

  UnitSummary _unit(Map<String, dynamic> m) => UnitSummary(
        id: m['id'] as String,
        slug: m['slug'] as String,
        titleTh: m['title_th'] as String,
        titleEs: m['title_es'] as String?,
        subtitleTh: m['subtitle_th'] as String,
        level: CefrX.parse(m['level'] as String),
        lessons: (m['lessons'] as List).map((e) {
          final l = (e as Map).cast<String, dynamic>();
          return LessonSummary(
            id: l['id'] as String,
            slug: l['slug'] as String,
            titleTh: l['title_th'] as String,
            estimatedMinutes: l['estimated_minutes'] as int,
            sortOrder: l['sort_order'] as int,
          );
        }).toList(),
      );

  @override
  Future<Lesson> lesson(String lessonId) async {
    final m = (_pack['lessons'] as Map)[lessonId];
    if (m == null) throw StateError('lesson $lessonId not in pack $kPackVersion');
    final j = (m as Map).cast<String, dynamic>();
    return Lesson(
      id: j['id'] as String,
      versionId: j['version_id'] as String,
      slug: j['slug'] as String,
      titleTh: j['title_th'] as String,
      titleEs: j['title_es'] as String?,
      goalTh: j['goal_th'] as String,
      estimatedMinutes: j['estimated_minutes'] as int,
      completionRules: CompletionRules.fromJson(
          (j['completion_rules'] as Map).cast<String, dynamic>()),
      blocks: (j['blocks'] as List)
          .map((e) => ContentBlock.fromJson((e as Map).cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  @override
  Future<Exercise> exercise(String exerciseId) async {
    final m = (_pack['exercises'] as Map)[exerciseId];
    if (m == null) throw StateError('exercise $exerciseId not in pack');
    return Exercise.fromJson((m as Map).cast<String, dynamic>());
  }

  @override
  Future<List<VocabSense>> senses(List<String> ids) async {
    final all = (_pack['senses'] as Map);
    return ids.where(all.containsKey).map((id) {
      final j = (all[id] as Map).cast<String, dynamic>();
      return VocabSense(
        id: j['id'] as String,
        lemma: j['lemma'] as String,
        pos: j['pos'] as String,
        gender: j['gender'] as String?,
        pluralForm: j['plural_form'] as String?,
        meaningTh: j['meaning_th'] as String,
        ipaPhonemic: j['ipa_phonemic'] as String?,
        ipaPhonetic: j['ipa_phonetic'] as String?,
        spainNote: j['spain_note'] as String?,
        examples: (j['examples'] as List? ?? const [])
            .map((e) => (
                  es: (e as Map)['es'] as String,
                  th: e['th'] as String,
                ))
            .toList(),
        collocations: (j['collocations'] as List? ?? const [])
            .map((e) => (
                  phrase: (e as Map)['phrase'] as String,
                  th: e['th'] as String,
                ))
            .toList(),
      );
    }).toList();
  }
}

/// Grammar/Why resolution, all local.
///
/// Tier order matters: the block's own pre-authored `why_l1_th` answers first,
/// instantly and free. Only "ถามครู AI" would reach a model, and that path is
/// not connected in this slice.
class PackGrammarRepository implements GrammarRepository {
  PackGrammarRepository({
    required CurriculumRepository curriculum,
    Map<String, dynamic>? pack,
  }) : _pack = pack ?? kContentPack;

  final Map<String, dynamic> _pack;

  Map<String, dynamic>? _concept(String? id) => id == null
      ? null
      : ((_pack['concepts'] as Map)[id] as Map?)?.cast<String, dynamic>();

  @override
  Future<WhyAnswer?> whyForBlock(String blockId) async {
    // Search every lesson for the block. Cheap at pack scale, and keeps the
    // caller from needing to know which lesson a block belongs to.
    for (final lesson in (_pack['lessons'] as Map).values) {
      for (final b in ((lesson as Map)['blocks'] as List)) {
        final m = (b as Map).cast<String, dynamic>();
        if (m['id'] != blockId) continue;
        final why = m['why_l1_th'] as String?;
        if (why == null || why.trim().isEmpty) return null;
        final c = _concept(m['concept_id'] as String?);
        return WhyAnswer(
          depth: WhyDepth.l1Simple,
          bodyTh: why,
          source: 'pack',
          conceptNameTh: c?['name_th'] as String?,
          deeperAvailable: c != null,
        );
      }
    }
    return null;
  }

  @override
  Future<WhyAnswer?> depth(String conceptId, WhyDepth d) async {
    final c = _concept(conceptId);
    if (c == null) return null;
    final body = switch (d) {
      WhyDepth.l1Simple => c['l1'],
      WhyDepth.l2Understand => c['l2'],
      WhyDepth.l3Deep => c['l3'],
      WhyDepth.l4Linguistic => null, // authored on demand; not in this pack
    } as String?;
    if (body == null) return null;
    return WhyAnswer(
      depth: d,
      bodyTh: body,
      source: 'pack',
      conceptNameTh: c['name_th'] as String?,
      spainNoteTh: c['spain_note'] as String?,
      thaiContrastTh: c['thai_contrast'] as String?,
      deeperAvailable: d == WhyDepth.l1Simple
          ? c['l2'] != null
          : d == WhyDepth.l2Understand
              ? c['l3'] != null
              : false,
    );
  }

  /// Development stub. Returns a message that says plainly it is not connected.
  /// It never fabricates a tutor answer, because a plausible-looking invented
  /// grammar explanation is worse than no answer at all.
  @override
  Future<WhyAnswer> askTutor({
    required String questionTh,
    String? conceptId,
    String? sentenceEs,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const WhyAnswer(
      depth: WhyDepth.l4Linguistic,
      bodyTh: 'ครู AI ยังไม่ได้เชื่อมต่อในเวอร์ชันนี้\n\n'
          'คำถามของคุณถูกบันทึกไว้แล้ว แต่ระบบจะไม่แสดงคำตอบที่แต่งขึ้นเอง '
          'เพราะคำอธิบายไวยากรณ์ที่ดูน่าเชื่อแต่ผิด อันตรายกว่าการไม่ตอบ\n\n'
          'ระหว่างนี้ลองกด “ดูละเอียด” เพื่อดูคำอธิบายที่ผู้เชี่ยวชาญเขียนไว้แล้วได้',
      source: 'ai_stub',
    );
  }
}

// --------------------------------------------------------------- learner ----

class LocalLearnerRepository implements LearnerRepository {
  LocalLearnerRepository(this._db, this._curriculum, this._attempts, this._speech);

  final AppDatabase _db;
  final CurriculumRepository _curriculum;
  final AttemptRepository _attempts;
  final SpeechRepository _speech;

  static const _kGoal = 'goal';
  static const _kMinutes = 'daily_goal_minutes';
  static const _kSelfRef = 'self_reference';
  static const _kStudied = 'has_studied_before';
  static const _kOnboarded = 'onboarding_complete';

  @override
  Future<LearnerPreferences> preferences() async {
    final m = await _db.allPreferences();
    return LearnerPreferences(
      goal: m[_kGoal] == null
          ? null
          : LearningGoal.values.firstWhere((g) => g.wire == m[_kGoal],
              orElse: () => LearningGoal.interest),
      dailyGoalMinutes: int.tryParse(m[_kMinutes] ?? '') ?? 15,
      selfReference: SelfReference.values
          .firstWhere((s) => s.wire == m[_kSelfRef], orElse: () => SelfReference.both),
      hasStudiedBefore: m[_kStudied] == 'true',
      onboardingComplete: m[_kOnboarded] == 'true',
    );
  }

  @override
  Future<void> savePreferences(LearnerPreferences p) async {
    if (p.goal != null) await _db.setPreference(_kGoal, p.goal!.wire);
    await _db.setPreference(_kMinutes, '${p.dailyGoalMinutes}');
    await _db.setPreference(_kSelfRef, p.selfReference.wire);
    await _db.setPreference(_kStudied, '${p.hasStudiedBefore}');
    await _db.setPreference(_kOnboarded, '${p.onboardingComplete}');
  }

  @override
  Future<LearnerStats> stats() async {
    final r = await _db.statsRow();
    return LearnerStats(
      lessonsCompleted: r.lessonsCompleted,
      totalMinutes: r.totalMinutes,
      xp: r.xp,
      currentStreak: r.currentStreak,
    );
  }

  @override
  Future<Map<String, LessonProgress>> progress() async {
    final rows = await _db.allProgress();
    return {
      for (final r in rows)
        r.lessonId: LessonProgress(
          lessonId: r.lessonId,
          state: switch (r.state) {
            'completed' => LessonState.completed,
            'in_progress' => LessonState.inProgress,
            _ => LessonState.notStarted,
          },
          lastBlockIndex: r.furthestBlock,
        )
    };
  }

  @override
  Future<void> markBlockViewed(String lessonId, int blockIndex) async {
    final existing = await _db.progressFor(lessonId);
    if (existing?.state == 'completed') return; // never regress a completion
    final furthest =
        blockIndex > (existing?.furthestBlock ?? 0) ? blockIndex : existing!.furthestBlock;
    await _db.upsertProgress(lessonId, 'in_progress', furthest);
  }

  /// Mirrors learning.complete_lesson(): evidence-gated and idempotent.
  ///
  /// DEVELOPMENT MIRROR ONLY. The server remains the authority; this exists so
  /// local mode behaves the same way rather than being a free pass.
  @override
  Future<CompletionResult> completeLesson(String lessonId) async {
    final lesson = await _curriculum.lesson(lessonId);
    final rules = lesson.completionRules;

    // An empty contract is a configuration error, not a free pass.
    if (rules.isEmpty) {
      throw StateError(
          'lesson $lessonId has no completion_rules; refusing to grant completion');
    }

    final existing = await _db.progressFor(lessonId);
    if (existing?.state == 'completed') {
      return const CompletionResult(
          completed: true, awarded: false, alreadyCompleted: true);
    }

    final correct = (await _attempts.gradedExerciseIds());
    final spoken = (await _speech.submittedExerciseIds());

    final missing = <String>[
      for (final id in rules.requiredCorrectExercises)
        if (!correct.contains(id)) 'correct:$id',
      for (final id in rules.requiredSpeechExercises)
        if (!spoken.contains(id)) 'speech:$id',
    ];

    if (missing.isNotEmpty) {
      return CompletionResult(
          completed: false, awarded: false, alreadyCompleted: false, missing: missing);
    }

    await _db.upsertProgress(lessonId, 'completed', lesson.blocks.length);

    final s = await _db.statsRow();
    await _db.writeStats(s.copyWith(
      lessonsCompleted: s.lessonsCompleted + 1,
      totalMinutes: s.totalMinutes + lesson.estimatedMinutes,
      xp: s.xp + 20,
      currentStreak: s.currentStreak == 0 ? 1 : s.currentStreak,
    ));

    return const CompletionResult(
        completed: true, awarded: true, alreadyCompleted: false);
  }

  /// Mirrors learning.build_daily_plan(). Deterministic, no model call, so Home
  /// renders instantly and offline.
  @override
  Future<DailyPlan> dailyPlan() async {
    final prefs = await preferences();
    final budget = prefs.dailyGoalMinutes;
    final prog = await progress();
    final units = await _curriculum.unitsForLevel(Cefr.preA1);

    final items = <PlanItem>[];
    var left = budget;

    LessonSummary? next;
    for (final u in units) {
      for (final l in u.lessons) {
        if (prog[l.id]?.state != LessonState.completed) {
          // Only lessons present in the pack are enterable.
          if ((kContentPack['lessons'] as Map).containsKey(l.id)) {
            next ??= l;
          }
        }
      }
    }

    if (next != null) {
      final m = next.estimatedMinutes.clamp(1, left);
      items.add(PlanItem(
        kind: 'lesson',
        labelTh: next.titleTh,
        minutes: m,
        lessonId: next.id,
        done: false,
      ));
      left -= m;
    }

    if (left >= 3) {
      items.add(PlanItem(kind: 'speaking', labelTh: 'ฝึกพูด', minutes: left));
    }

    return DailyPlan(budgetMinutes: budget, items: items);
  }

  /// Local mode has no server session; a synthetic id keeps the call shape
  /// identical so the UI code path is the same in both modes.
  @override
  Future<String> startSession({required String kind, String? lessonId}) async =>
      'local-session-$kind-${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<void> endSession(String sessionId) async {}
}

// --------------------------------------------------------------- attempts ---

class LocalAttemptRepository implements AttemptRepository {
  LocalAttemptRepository(this._db, this._curriculum);

  final AppDatabase _db;
  final CurriculumRepository _curriculum;

  @override
  Future<AttemptFeedback> submit({
    required String attemptId,
    required String exerciseId,
    required String answer,
    required String sessionId,
    int? latencyMs,
  }) async {
    // Idempotent replay, exactly like the server: same key => stored verdict.
    final prior = await _db.attemptById(attemptId);
    if (prior != null && prior.feedbackJson != null) {
      final j = (jsonDecode(prior.feedbackJson!) as Map).cast<String, dynamic>();
      return AttemptFeedback.fromJson({...j, 'replayed': true});
    }

    final ex = await _curriculum.exercise(exerciseId);
    final isCorrect = AnswerMatcher.matches(
      answer,
      accepted: ex.rules.accepted,
      pattern: ex.rules.pattern,
      accentInsensitive: ex.rules.accentInsensitive,
    );

    final feedback = <String, dynamic>{
      'is_correct': isCorrect,
      'your_answer': answer,
      'correct': ex.rules.accepted.isNotEmpty
          ? ex.rules.accepted.first
          : ex.rules.modelAnswer,
      'what_changed': ex.feedback['what_changed'],
      'why_th': ex.feedback['why_th'],
      'rule_concept': ex.conceptId,
      'contrast': ex.feedback['contrast'],
      'error_codes': isCorrect ? const <String>[] : ex.rules.errorCodes,
      'can_retry': true,
      'deep_available': ex.conceptId != null,
      'replayed': false,
    };

    await _db.saveAttempt(AttemptRow(
      attemptId: attemptId,
      exerciseId: exerciseId,
      answer: answer,
      sessionId: sessionId,
      isCorrect: isCorrect,
      feedbackJson: jsonEncode(feedback),
      synced: false,
      createdAt: DateTime.now(),
    ));

    return AttemptFeedback.fromJson(feedback);
  }

  @override
  Future<Set<String>> gradedExerciseIds() async =>
      (await _db.correctExerciseIds()).toSet();
}

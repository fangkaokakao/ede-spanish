import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../local/app_database.dart';

/// Supabase implementations, written against the RPC contracts that the pgTAP
/// suite covers (107 assertions).
///
/// Contract notes that shape this code:
///   * No client-callable RPC takes a learner id. Identity is auth.uid().
///   * `is_correct` is decided by the server. This class never grades.
///   * `submit_attempt` requires an open server session id.
///   * The attempt id is the idempotency key; replaying returns the same
///     verdict and creates no duplicate evidence.
///   * Derived tables are SELECT-only, so progress/stats are read, never written.
class SupabaseCurriculumRepository implements CurriculumRepository {
  SupabaseCurriculumRepository(this._c);
  final SupabaseClient _c;

  @override
  Future<List<CefrLevel>> levels() async {
    final rows = await _c
        .schema('content')
        .from('cefr_levels')
        .select('level,name_th,tagline_th,is_available')
        .order('ordinal');
    return rows
        .map((m) => CefrLevel(
              level: CefrX.parse(m['level'] as String),
              nameTh: m['name_th'] as String,
              taglineTh: m['tagline_th'] as String,
              isAvailable: m['is_available'] as bool,
            ))
        .toList();
  }

  @override
  Future<List<UnitSummary>> unitsForLevel(Cefr level) async {
    final rows = await _c
        .schema('content')
        .from('curriculum_nodes')
        .select('id,slug,title_th,title_es,subtitle_th,level,'
            'lessons:lessons(id,slug,sort_order,estimated_minutes,'
            'lesson_versions(title_th,version))')
        .eq('kind', 'unit')
        .eq('level', level.wire)
        .order('sort_order');
    return rows.map(_unit).toList();
  }

  @override
  Future<UnitSummary> unit(String unitId) async {
    final m = await _c
        .schema('content')
        .from('curriculum_nodes')
        .select('id,slug,title_th,title_es,subtitle_th,level,'
            'lessons:lessons(id,slug,sort_order,estimated_minutes,'
            'lesson_versions(title_th,version))')
        .eq('id', unitId)
        .single();
    return _unit(m);
  }

  UnitSummary _unit(Map<String, dynamic> m) => UnitSummary(
        id: m['id'] as String,
        slug: m['slug'] as String,
        titleTh: m['title_th'] as String,
        titleEs: m['title_es'] as String?,
        subtitleTh: (m['subtitle_th'] as String?) ?? '',
        level: CefrX.parse(m['level'] as String),
        lessons: ((m['lessons'] as List?) ?? const [])
            .map((e) {
              final l = (e as Map).cast<String, dynamic>();
              final versions = (l['lesson_versions'] as List?) ?? const [];
              return LessonSummary(
                id: l['id'] as String,
                slug: l['slug'] as String,
                titleTh: versions.isEmpty
                    ? (l['slug'] as String)
                    : (versions.first as Map)['title_th'] as String,
                estimatedMinutes: (l['estimated_minutes'] as int?) ?? 8,
                sortOrder: (l['sort_order'] as int?) ?? 0,
              );
            })
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  @override
  Future<Lesson> lesson(String lessonId) async {
    final l = await _c
        .schema('content')
        .from('lessons')
        .select('id,slug,estimated_minutes,current_version,'
            'lesson_versions(id,version,title_th,title_es,goal_th,completion_rules,'
            'content_blocks(id,sort_order,block_type,payload,concept_id,why_l1_th))')
        .eq('id', lessonId)
        .single();

    final versions = (l['lesson_versions'] as List).cast<Map>();
    final v = versions
        .firstWhere((x) => x['version'] == l['current_version'],
            orElse: () => versions.first)
        .cast<String, dynamic>();

    return Lesson(
      id: l['id'] as String,
      versionId: v['id'] as String,
      slug: l['slug'] as String,
      titleTh: v['title_th'] as String,
      titleEs: v['title_es'] as String?,
      goalTh: v['goal_th'] as String,
      estimatedMinutes: (l['estimated_minutes'] as int?) ?? 8,
      completionRules: CompletionRules.fromJson(
          ((v['completion_rules'] as Map?) ?? const {}).cast<String, dynamic>()),
      blocks: ((v['content_blocks'] as List?) ?? const [])
          .map((e) => ContentBlock.fromJson((e as Map).cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  @override
  Future<Exercise> exercise(String exerciseId) async {
    final m = await _c
        .schema('content')
        .from('exercises')
        .select('id,template_id,objective_id,concept_id,prompt_th,payload,'
            'answer_rules,feedback')
        .eq('id', exerciseId)
        .single();
    return Exercise.fromJson(m);
  }

  @override
  Future<List<VocabSense>> senses(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _c
        .schema('content')
        .from('vocabulary_senses')
        .select('id,meaning_th,spain_note,'
            'vocabulary_entries(lemma,pos,gender,plural_form,ipa_phonemic,ipa_phonetic),'
            'vocabulary_examples(sentence_es,meaning_th),'
            'collocations(phrase,meaning_th)')
        .inFilter('id', ids);

    return rows.map((m) {
      final e = ((m['vocabulary_entries'] as Map?) ?? const {}).cast<String, dynamic>();
      return VocabSense(
        id: m['id'] as String,
        lemma: (e['lemma'] as String?) ?? '',
        pos: (e['pos'] as String?) ?? '',
        gender: e['gender'] as String?,
        pluralForm: e['plural_form'] as String?,
        meaningTh: m['meaning_th'] as String,
        ipaPhonemic: e['ipa_phonemic'] as String?,
        ipaPhonetic: e['ipa_phonetic'] as String?,
        spainNote: m['spain_note'] as String?,
        examples: ((m['vocabulary_examples'] as List?) ?? const [])
            .map((x) => (
                  es: (x as Map)['sentence_es'] as String,
                  th: x['meaning_th'] as String,
                ))
            .toList(),
        collocations: ((m['collocations'] as List?) ?? const [])
            .map((x) => (
                  phrase: (x as Map)['phrase'] as String,
                  th: x['meaning_th'] as String,
                ))
            .toList(),
      );
    }).toList();
  }
}

class SupabaseLearnerRepository implements LearnerRepository {
  SupabaseLearnerRepository(this._c, this._db);
  final SupabaseClient _c;
  final AppDatabase _db; // local cache + offline outbox

  String get _uid => _c.auth.currentUser!.id;

  @override
  Future<LearnerPreferences> preferences() async {
    final m = await _c
        .schema('learning')
        .from('learner_preferences')
        .select('goal,daily_goal_minutes,self_reference,explanation_depth')
        .eq('learner_id', _uid)
        .maybeSingle();
    if (m == null) return const LearnerPreferences();
    final local = await _db.allPreferences();
    return LearnerPreferences(
      goal: m['goal'] == null
          ? null
          : LearningGoal.values.firstWhere((g) => g.wire == m['goal'],
              orElse: () => LearningGoal.interest),
      dailyGoalMinutes: (m['daily_goal_minutes'] as int?) ?? 15,
      selfReference: SelfReference.values.firstWhere(
          (s) => s.wire == m['self_reference'],
          orElse: () => SelfReference.both),
      explanationDepth: (m['explanation_depth'] as int?) ?? 1,
      // Onboarding completion is a client-side milestone, not learner data.
      onboardingComplete: local['onboarding_complete'] == 'true',
      hasStudiedBefore: local['has_studied_before'] == 'true',
    );
  }

  @override
  Future<void> savePreferences(LearnerPreferences p) async {
    await _c.schema('learning').from('learner_preferences').update({
      if (p.goal != null) 'goal': p.goal!.wire,
      'daily_goal_minutes': p.dailyGoalMinutes,
      'self_reference': p.selfReference.wire,
      'explanation_depth': p.explanationDepth,
    }).eq('learner_id', _uid);

    await _db.setPreference('onboarding_complete', '${p.onboardingComplete}');
    await _db.setPreference('has_studied_before', '${p.hasStudiedBefore}');
  }

  /// SELECT-only table. Counters are written by learning.complete_lesson().
  @override
  Future<LearnerStats> stats() async {
    final m = await _c
        .schema('learning')
        .from('learner_stats')
        .select('lessons_completed,total_minutes,xp,current_streak,words_mastered')
        .eq('learner_id', _uid)
        .maybeSingle();
    if (m == null) return const LearnerStats();
    return LearnerStats(
      lessonsCompleted: (m['lessons_completed'] as int?) ?? 0,
      totalMinutes: (m['total_minutes'] as int?) ?? 0,
      xp: (m['xp'] as int?) ?? 0,
      currentStreak: (m['current_streak'] as int?) ?? 0,
      wordsMastered: (m['words_mastered'] as int?) ?? 0,
    );
  }

  @override
  Future<Map<String, LessonProgress>> progress() async {
    final rows = await _c
        .schema('learning')
        .from('lesson_progress')
        .select('lesson_id,state,last_block_index')
        .eq('learner_id', _uid);
    return {
      for (final r in rows)
        r['lesson_id'] as String: LessonProgress(
          lessonId: r['lesson_id'] as String,
          state: switch (r['state'] as String) {
            'completed' => LessonState.completed,
            'in_progress' => LessonState.inProgress,
            _ => LessonState.notStarted,
          },
          lastBlockIndex: (r['last_block_index'] as int?) ?? 0,
        )
    };
  }

  /// Reading position is one of the few fields a client legitimately owns.
  /// `state` may never be set to 'completed' here — the RLS policy and a
  /// trigger both reject it.
  @override
  Future<void> markBlockViewed(String lessonId, int blockIndex) async {
    await _c.schema('learning').from('lesson_progress').upsert({
      'learner_id': _uid,
      'lesson_id': lessonId,
      'state': 'in_progress',
      'last_block_index': blockIndex,
    }, onConflict: 'learner_id,lesson_id');
  }

  @override
  Future<CompletionResult> completeLesson(String lessonId) async {
    final res = await _c
        .schema('learning')
        .rpc('complete_lesson', params: {'p_lesson_id': lessonId});
    return CompletionResult.fromJson((res as Map).cast<String, dynamic>());
  }

  @override
  Future<DailyPlan> dailyPlan() async {
    final res = await _c.schema('learning').rpc('build_daily_plan');
    final m = (res as Map).cast<String, dynamic>();
    return DailyPlan(
      budgetMinutes: (m['budget_min'] as int?) ?? 15,
      items: ((m['items'] as List?) ?? const []).map((e) {
        final i = (e as Map).cast<String, dynamic>();
        return PlanItem(
          kind: i['kind'] as String,
          labelTh: i['label_th'] as String,
          minutes: (i['minutes'] as num).toInt(),
          lessonId: i['lesson_id'] as String?,
          count: (i['count'] as num?)?.toInt(),
        );
      }).toList(),
    );
  }

  @override
  Future<String> startSession({required String kind, String? lessonId}) async {
    final res = await _c.schema('learning').rpc('start_session', params: {
      'p_kind': kind,
      if (lessonId != null) 'p_lesson_id': lessonId,
    });
    return res as String;
  }

  @override
  Future<void> endSession(String sessionId) async {
    await _c
        .schema('learning')
        .rpc('end_session', params: {'p_session_id': sessionId});
  }
}

class SupabaseAttemptRepository implements AttemptRepository {
  SupabaseAttemptRepository(this._c, this._db);
  final SupabaseClient _c;
  final AppDatabase _db;

  /// The server decides correctness. The attempt is written to the local outbox
  /// FIRST so a dropped connection cannot lose the learner's work; the same
  /// attempt id replays harmlessly.
  @override
  Future<AttemptFeedback> submit({
    required String attemptId,
    required String exerciseId,
    required String answer,
    required String sessionId,
    int? latencyMs,
  }) async {
    await _db.saveAttempt(AttemptRow(
      attemptId: attemptId,
      exerciseId: exerciseId,
      answer: answer,
      sessionId: sessionId,
      isCorrect: null,
      feedbackJson: null,
      synced: false,
      createdAt: DateTime.now(),
    ));

    final res = await _c.schema('assess').rpc('submit_attempt', params: {
      'p_attempt_id': attemptId,
      'p_exercise_id': exerciseId,
      'p_answer': {'value': answer},
      'p_session_id': sessionId,
      'p_latency_ms': latencyMs,
    });

    final j = (res as Map).cast<String, dynamic>();
    final fb = AttemptFeedback.fromJson(j);

    await _db.saveAttempt(AttemptRow(
      attemptId: attemptId,
      exerciseId: exerciseId,
      answer: answer,
      sessionId: sessionId,
      isCorrect: fb.isCorrect,
      feedbackJson: jsonEncode(j),
      synced: true,
      createdAt: DateTime.now(),
    ));

    return fb;
  }

  @override
  Future<Set<String>> gradedExerciseIds() async {
    final rows = await _c
        .schema('assess')
        .from('exercise_attempts')
        .select('exercise_id')
        .eq('is_correct', true);
    return rows.map((r) => r['exercise_id'] as String).toSet();
  }
}

/// Wraps the device recorder and additionally registers the submission with
/// assess.submit_speech(). Still returns no verdict: evaluation is a separate
/// server pipeline that is not connected.
class SupabaseSpeechRepository implements SpeechRepository {
  SupabaseSpeechRepository(this._c, this._inner);
  final SupabaseClient _c;
  final SpeechRepository _inner;

  @override
  Future<bool> hasPermission() => _inner.hasPermission();
  @override
  Future<void> startRecording(String filePath) => _inner.startRecording(filePath);
  @override
  Future<String?> stopRecording() => _inner.stopRecording();
  @override
  Future<void> playback(String filePath) => _inner.playback(filePath);
  @override
  Future<void> stopPlayback() => _inner.stopPlayback();
  @override
  Future<Set<String>> submittedExerciseIds() => _inner.submittedExerciseIds();

  @override
  Future<void> submitSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    String? audioPath,
    int? durationMs,
  }) async {
    final uid = _c.auth.currentUser!.id;
    String? remotePath;

    if (audioPath != null) {
      // Path must sit inside the caller's own folder; submit_speech() rejects
      // anything else with 42501.
      remotePath = 'learner-audio/$uid/${DateTime.now().year}/$submissionId.m4a';
    }

    await _inner.submitSpeech(
      submissionId: submissionId,
      exerciseId: exerciseId,
      sessionId: sessionId,
      audioPath: remotePath,
      durationMs: durationMs,
    );

    await _c.schema('assess').rpc('submit_speech', params: {
      'p_submission_id': submissionId,
      'p_exercise_id': exerciseId,
      'p_session_id': sessionId,
      'p_audio_path': remotePath,
      'p_duration_ms': durationMs,
    });
  }
}

/// Reads authored grammar from Postgres. Still no AI: L1–L3 are curriculum
/// content, and the tutor tier is not connected in this slice.
class SupabaseGrammarRepository implements GrammarRepository {
  SupabaseGrammarRepository(this._c, this._fallback);
  final SupabaseClient _c;
  final GrammarRepository _fallback;

  @override
  Future<WhyAnswer?> whyForBlock(String blockId) async {
    final m = await _c
        .schema('content')
        .from('content_blocks')
        .select('why_l1_th,concept_id,grammar_concepts(name_th)')
        .eq('id', blockId)
        .maybeSingle();
    final why = m?['why_l1_th'] as String?;
    if (why == null || why.trim().isEmpty) return null;
    return WhyAnswer(
      depth: WhyDepth.l1Simple,
      bodyTh: why,
      source: 'pack',
      conceptNameTh:
          ((m!['grammar_concepts'] as Map?)?['name_th']) as String?,
      deeperAvailable: m['concept_id'] != null,
    );
  }

  @override
  Future<WhyAnswer?> depth(String conceptId, WhyDepth d) async {
    final m = await _c
        .schema('content')
        .from('grammar_concepts')
        .select('name_th,explain_l1_th,explain_l2_th,explain_l3_th,explain_l4_th,'
            'spain_usage_note')
        .eq('id', conceptId)
        .maybeSingle();
    if (m == null) return null;
    final body = switch (d) {
      WhyDepth.l1Simple => m['explain_l1_th'],
      WhyDepth.l2Understand => m['explain_l2_th'],
      WhyDepth.l3Deep => m['explain_l3_th'],
      WhyDepth.l4Linguistic => m['explain_l4_th'],
    } as String?;
    if (body == null) return null;
    return WhyAnswer(
      depth: d,
      bodyTh: body,
      source: 'pack',
      conceptNameTh: m['name_th'] as String?,
      spainNoteTh: m['spain_usage_note'] as String?,
      deeperAvailable: switch (d) {
        WhyDepth.l1Simple => m['explain_l2_th'] != null,
        WhyDepth.l2Understand => m['explain_l3_th'] != null,
        _ => false,
      },
    );
  }

  @override
  Future<WhyAnswer> askTutor({
    required String questionTh,
    String? conceptId,
    String? sentenceEs,
  }) =>
      _fallback.askTutor(
          questionTh: questionTh, conceptId: conceptId, sentenceEs: sentenceEs);
}

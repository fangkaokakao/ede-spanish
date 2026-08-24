import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/domain/answer_matcher.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curriculum = PackCurriculumRepository();
  final grammar = PackGrammarRepository(curriculum: curriculum);
  const lessonId = '44444444-4444-4444-8444-444444444403';

  group('pack curriculum', () {
    test('only Pre-A1 is available; higher levels are visible but locked', () async {
      final levels = await curriculum.levels();
      expect(levels.length, 7);
      expect(levels.where((l) => l.isAvailable).map((l) => l.level), [Cefr.preA1]);
    });

    test('the lesson parses every block type in authored order', () async {
      final lesson = await curriculum.lesson(lessonId);
      expect(lesson.titleEs, 'Me llamo…');
      expect(lesson.blocks.map((b) => b.sortOrder).toList(),
          List.generate(lesson.blocks.length, (i) => i + 1));

      final types = lesson.blocks.map((b) => b.runtimeType.toString()).toSet();
      expect(types, containsAll(<String>{
        'ExampleBlock',
        'PronunciationBlock',
        'ComparisonBlock',
        'DialogueBlock',
        'VocabularyBlock',
        'ReviewBlock',
        'ExerciseEmbedBlock',
      }));
    });

    test('the lesson carries a non-empty completion contract', () async {
      final lesson = await curriculum.lesson(lessonId);
      expect(lesson.completionRules.isEmpty, isFalse);
      expect(lesson.completionRules.requiredCorrectExercises.length, 2);
      expect(lesson.completionRules.requiredSpeechExercises.length, 1);
    });

    test('the example block has morphological segmentation for llamo', () async {
      final lesson = await curriculum.lesson(lessonId);
      final ex = lesson.blocks.whereType<ExampleBlock>().first;
      final llamo = ex.tokens.firstWhere((t) => t.text == 'llamo');
      expect(llamo.segments.map((s) => s.text), ['llam-', '-o']);
      // The gloss must NOT claim -o means "ฉัน" on its own.
      expect(llamo.segments.last.glossTh, isNot(contains('แปลว่า ฉัน')));
    });

    test('the pronunciation block teaches ll, and yeismo, not the lateral',
        () async {
      final lesson = await curriculum.lesson(lessonId);
      final p = lesson.blocks.whereType<PronunciationBlock>().first;
      expect(p.focus, 'll');
      expect(p.targetSlug, 'll_y_yeismo');
      expect(p.ipaPhonemic, 'ʝ');
      expect(p.ipaPhonemic, isNot(contains('ʎ')));
      // The contrast is a real minimal pair for a Thai learner: /ʝ/ vs /l/.
      expect({p.contrastA, p.contrastB}, {'lamo', 'llamo'});
    });

    test('vosotros appears as a first-class option in the comparison', () async {
      final lesson = await curriculum.lesson(lessonId);
      final c = lesson.blocks.whereType<ComparisonBlock>().first;
      expect(c.rows.map((r) => r.es), contains('¿Cómo os llamáis?'));
      // ustedes is present but as the FORMAL option, not the plural default.
      final ustedes = c.rows.firstWhere((r) => r.es.contains('se llaman'));
      expect(ustedes.register, 'formal');
    });

    test('senses expose phonemic and phonetic IPA separately', () async {
      final s = await curriculum.senses(
          const ['88888888-8888-4888-8888-888888888801']);
      expect(s.single.lemma, 'llamarse');
      expect(s.single.ipaPhonemic, startsWith('/'));
      expect(s.single.ipaPhonetic, startsWith('['));
      expect(s.single.ipaPhonemic, isNot(contains('ʎ')));
    });

    test('the authored own-name exercise accepts a real learner name', () async {
      final exercise = await curriculum.exercise(
        '66666666-6666-4666-8666-666666666601',
      );
      expect(
        AnswerMatcher.matches(
          'Me llamo Somchai',
          accepted: exercise.rules.accepted,
          pattern: exercise.rules.pattern,
          accentInsensitive: exercise.rules.accentInsensitive,
        ),
        isTrue,
      );
    });

    test('a missing lesson fails loudly rather than silently', () {
      expect(() => curriculum.lesson('nope'), throwsStateError);
    });
  });

  group('Why resolution (tier order)', () {
    test('tier 0 resolves the pre-authored answer from the pack', () async {
      final a = await grammar.whyForBlock('blk-l3-01');
      expect(a, isNotNull);
      expect(a!.source, 'pack');
      expect(a.depth, WhyDepth.l1Simple);
      expect(a.deeperAvailable, isTrue);
    });

    test('a block with no authored answer returns null, not a guess', () async {
      expect(await grammar.whyForBlock('blk-l3-07'), isNull);
    });

    test('deeper tiers walk L2 then L3, all from authored content', () async {
      const concept = '11111111-1111-4111-8111-111111111101';
      final l2 = await grammar.depth(concept, WhyDepth.l2Understand);
      final l3 = await grammar.depth(concept, WhyDepth.l3Deep);
      expect(l2!.source, 'pack');
      expect(l3!.source, 'pack');
      expect(l2.bodyTh, contains('hablo / hablas / habla'));
      expect(l3.bodyTh, contains('imperfecto'));
      expect(l3.deeperAvailable, isFalse);
    });

    test('L2/L3 contain no forbidden oversimplification', () async {
      const concept = '11111111-1111-4111-8111-111111111101';
      for (final d in [WhyDepth.l1Simple, WhyDepth.l2Understand, WhyDepth.l3Deep]) {
        final a = await grammar.depth(concept, d);
        expect(a!.bodyTh, isNot(contains('-o แปลว่า ฉัน')));
        expect(a.bodyTh, isNot(contains('เสมอ')));
      }
    });

    test('the tutor tier is a labelled stub and never fabricates an answer',
        () async {
      final a = await grammar.askTutor(questionTh: 'ทำไม');
      expect(a.source, 'ai_stub');
      expect(a.bodyTh, contains('ยังไม่ได้เชื่อมต่อ'));
    });
  });
}

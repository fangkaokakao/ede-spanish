import 'package:ede/data/local/content_pack.dart';
import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curriculum = PackCurriculumRepository();

  group('Foundation 0 lesson ordering', () {
    test('the new opening lesson sits before "Hola, ¿qué tal?" by sortOrder',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      expect(unit.lessons.map((l) => l.id).toList(),
          [kLessonFoundation0L0Id, kLessonFoundation0L1Id]);
      expect(unit.lessons.map((l) => l.sortOrder).toList(), [0, 1]);
    });

    test('the alphabet/vowels lesson slug is marked available', () {
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0L0Slug));
      // Existing slugs stay available too.
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0L1Slug));
      expect(kAvailableLessonSlugs, contains('pre-a1-u1-l3'));
    });
  });

  group('Foundation 0 L0 (alphabet + vowels) content', () {
    test('parses every block and carries a non-empty completion contract',
        () async {
      final lesson = await curriculum.lesson(kLessonFoundation0L0Id);
      expect(lesson.titleEs, 'El alfabeto y las vocales');
      expect(lesson.blocks.map((b) => b.sortOrder).toList(),
          List.generate(lesson.blocks.length, (i) => i + 1));
      expect(lesson.completionRules.isEmpty, isFalse);
      expect(lesson.completionRules.requiredCorrectExercises.length, 4);
      expect(lesson.completionRules.requiredSpeechExercises.length, 1);
      expect(lesson.completionRules.minBlocksViewed, lesson.blocks.length);
    });

    test('teaches all five Spanish vowels as pure, stable sounds', () async {
      final lesson = await curriculum.lesson(kLessonFoundation0L0Id);
      final vowels = lesson.blocks.whereType<PronunciationBlock>().toList();
      expect(vowels.map((v) => v.focus).toList(), ['a', 'e', 'i', 'o', 'u']);
      for (final v in vowels) {
        expect(v.ipaPhonemic, isNotNull);
        expect(v.noteTh, isNotEmpty);
        // Every vowel has a reasonable Thai transliteration bridge, unlike
        // sounds with no good Thai equivalent (those stay null).
        expect(v.thaiHelperTh, isNotNull);
      }
    });

    test('an unknown lesson id is never silently accepted', () {
      expect(() => curriculum.lesson('does-not-exist'), throwsStateError);
    });

    test('existing Unit 1 Lesson 3 and Foundation 0 L1 ids are untouched', () {
      expect(kLessonMeLlamoId, '44444444-4444-4444-8444-444444444403');
      expect(kUnitPreA1U1Id, '22222222-2222-4222-8222-222222222203');
      expect(kLessonFoundation0L1Id, '44444444-4444-4444-8444-444444444401');
      expect(kUnitFoundation0Id, '22222222-2222-4222-8222-222222222200');
    });
  });
}

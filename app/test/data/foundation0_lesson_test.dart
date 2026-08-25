import 'package:ede/data/local/content_pack.dart';
import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curriculum = PackCurriculumRepository();

  group('Foundation 0 unit ordering', () {
    test('units are sorted by sortOrder — Foundation 0 comes before Unit 1', () async {
      final units = await curriculum.unitsForLevel(Cefr.preA1);
      expect(units.map((u) => u.id).toList(),
          [kUnitFoundation0Id, kUnitPreA1U1Id]);
      expect(units.map((u) => u.sortOrder).toList(), [0, 1]);
    });

    test('the Foundation 0 lesson slug is marked available', () {
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0L1Slug));
      expect(kAvailableLessonSlugs, contains('pre-a1-u1-l3'));
    });
  });

  group('Foundation 0 lesson content', () {
    test('parses every block and carries a non-empty completion contract',
        () async {
      final lesson = await curriculum.lesson(kLessonFoundation0L1Id);
      expect(lesson.titleEs, 'Hola, ¿qué tal?');
      expect(lesson.blocks.map((b) => b.sortOrder).toList(),
          List.generate(lesson.blocks.length, (i) => i + 1));
      expect(lesson.completionRules.isEmpty, isFalse);
      expect(lesson.completionRules.requiredCorrectExercises.length, 2);
      expect(lesson.completionRules.requiredSpeechExercises.length, 1);
      expect(lesson.completionRules.minBlocksViewed, lesson.blocks.length);
    });

    test('teaches distinción (c/z as /θ/), never seseo, via a real minimal pair',
        () async {
      final lesson = await curriculum.lesson(kLessonFoundation0L1Id);
      final p = lesson.blocks.whereType<PronunciationBlock>().first;
      expect(p.ipaPhonemic, 'θ');
      expect({p.contrastA, p.contrastB}, {'casa', 'caza'});
    });

    test('existing Unit 1 Lesson 3 ids are untouched', () {
      expect(kLessonMeLlamoId, '44444444-4444-4444-8444-444444444403');
      expect(kUnitPreA1U1Id, '22222222-2222-4222-8222-222222222203');
    });
  });
}

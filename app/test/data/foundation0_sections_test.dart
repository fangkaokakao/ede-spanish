import 'package:ede/data/local/content_pack.dart';
import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curriculum = PackCurriculumRepository();

  group('Foundation 0 is sound-and-reading first, not conversational', () {
    test('Foundation 0 still comes before Pre-A1 Unit 1', () async {
      final units = await curriculum.unitsForLevel(Cefr.preA1);
      expect(units.map((u) => u.id).toList(),
          [kUnitFoundation0Id, kUnitPreA1U1Id]);
    });

    test('the alphabet lesson is the actual first lesson in learning order',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      expect(unit.lessons.first.id, kLessonFoundation0S1Id);
      expect(unit.lessons.first.slug, kLessonFoundation0S1Slug);
    });

    test('the vowel-a lesson is second, ahead of the conversational lesson',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      final ids = unit.lessons.map((l) => l.id).toList();
      expect(ids.indexOf(kLessonFoundation0S2Id),
          lessThan(ids.indexOf(kLessonFoundation0L1Id)));
    });

    test(
        'the original conversational lesson keeps its stable id/slug and is '
        'still present, just moved to a bonus slot after the sound curriculum',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      expect(kLessonFoundation0L1Id, '44444444-4444-4444-8444-444444444401');
      expect(unit.lessons.last.id, kLessonFoundation0L1Id);
      // Untouched content: still the same greeting lesson.
      final lesson = await curriculum.lesson(kLessonFoundation0L1Id);
      expect(lesson.titleEs, 'Hola, ¿qué tal?');
    });

    test('all three Foundation 0 lessons are available to enter', () {
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0S1Slug));
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0S2Slug));
      expect(kAvailableLessonSlugs, contains(kLessonFoundation0L1Slug));
    });
  });

  group('Foundation 0 course map sections', () {
    test('exposes 10 numbered sections plus one bonus section, in order',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      expect(unit.sections.length, 11);
      expect(unit.sections.map((s) => s.sortOrder).toList(),
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100]);
    });

    test('section 1 holds the alphabet lesson, section 2 the vowel-a lesson',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      final s1 = unit.sections.firstWhere((s) => s.sortOrder == 1);
      final s2 = unit.sections.firstWhere((s) => s.sortOrder == 2);
      expect(s1.lessons.single.id, kLessonFoundation0S1Id);
      expect(s2.lessons.single.id, kLessonFoundation0S2Id);
    });

    test('sections 3-10 have no authored lessons yet (never fabricated)',
        () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      for (final s in unit.sections.where(
          (s) => s.sortOrder >= 3 && s.sortOrder <= 10)) {
        expect(s.lessons, isEmpty, reason: '${s.id} should have no lessons yet');
      }
    });

    test('the bonus section holds the conversational lesson', () async {
      final unit = await curriculum.unit(kUnitFoundation0Id);
      final bonus = unit.sections.firstWhere((s) => s.sortOrder == 100);
      expect(bonus.lessons.single.id, kLessonFoundation0L1Id);
    });
  });

  group('the alphabet lesson (Section 1)', () {
    test('teaches all 27 Spanish letters including ñ', () async {
      final lesson = await curriculum.lesson(kLessonFoundation0S1Id);
      final grid = lesson.blocks.whereType<AlphabetBlock>().single;
      expect(grid.letters.length, 27);
      expect(grid.letters.map((l) => l.lower), contains('ñ'));
    });

    test('has a non-empty completion contract requiring the letter exercises',
        () async {
      final lesson = await curriculum.lesson(kLessonFoundation0S1Id);
      expect(lesson.completionRules.isEmpty, isFalse);
      expect(lesson.completionRules.requiredCorrectExercises.length, 2);
      expect(lesson.completionRules.requiredSpeechExercises.length, 1);
    });
  });

  group('the vowel-a lesson (Section 2, reference pattern)', () {
    late Lesson lesson;
    setUpAll(() async {
      lesson = await curriculum.lesson(kLessonFoundation0S2Id);
    });

    test('teaches /a/ with a Thai pronunciation bridge, never claiming identity',
        () async {
      final p = lesson.blocks.whereType<PronunciationBlock>().single;
      expect(p.ipaPhonemic, 'a');
      expect(p.thaiHelperTh, 'อา');
      expect(p.showSpainBadge, isFalse);
      // The card copy must never claim the Thai and Spanish sounds are the
      // same — this is enforced by the widget (see pronunciation_card_test),
      // but the content itself must not embed an "identical" claim either.
      expect(p.noteTh, isNot(contains('เหมือนกันทุกประการ')));
    });

    test('carries a worked example with syllable segmentation', () async {
      final p = lesson.blocks.whereType<PronunciationBlock>().single;
      expect(p.exampleEs, 'casa');
      expect(p.exampleSyllables, ['ca', 'sa']);
      expect(p.exampleMeaningTh, isNotNull);
    });

    test('has a non-empty completion contract', () async {
      expect(lesson.completionRules.isEmpty, isFalse);
      expect(lesson.completionRules.requiredCorrectExercises.length, 2);
      expect(lesson.completionRules.requiredSpeechExercises.length, 1);
    });
  });
}

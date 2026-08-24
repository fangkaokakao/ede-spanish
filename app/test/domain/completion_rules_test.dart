import 'package:ede/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompletionRules', () {
    test('parses the authored contract', () {
      final r = CompletionRules.fromJson(const {
        'required_correct_exercises': ['e1', 'e2'],
        'required_speech_exercises': ['e3'],
        'min_blocks_viewed': 7,
      });
      expect(r.requiredCorrectExercises, ['e1', 'e2']);
      expect(r.requiredSpeechExercises, ['e3']);
      expect(r.minBlocksViewed, 7);
      expect(r.isEmpty, isFalse);
    });

    // An empty contract must be detectable, because a lesson with no evidence
    // requirement is a trust button and complete_lesson() refuses it.
    test('an absent contract reports itself as empty', () {
      expect(CompletionRules.fromJson(const {}).isEmpty, isTrue);
    });
  });

  group('CompletionRules.missingFor (centralized completion logic)', () {
    const rules = CompletionRules(
      requiredCorrectExercises: ['c1', 'c2'],
      requiredSpeechExercises: ['s1'],
      minBlocksViewed: 5,
    );

    test('a fresh lesson is missing every requirement', () {
      final missing = rules.missingFor(
        correctExerciseIds: const {},
        spokenExerciseIds: const {},
        blocksViewed: 0,
      );
      expect(missing, containsAll(<String>['correct:c1', 'correct:c2', 'speech:s1', 'blocks_viewed']));
    });

    test('minBlocksViewed is enforced, not just exercise evidence', () {
      // Every exercise is done, but the learner has only reached block 3 of 5.
      final missing = rules.missingFor(
        correctExerciseIds: const {'c1', 'c2'},
        spokenExerciseIds: const {'s1'},
        blocksViewed: 3,
      );
      expect(missing, ['blocks_viewed']);
    });

    test('reaching exactly minBlocksViewed satisfies the reading requirement', () {
      final missing = rules.missingFor(
        correctExerciseIds: const {'c1', 'c2'},
        spokenExerciseIds: const {'s1'},
        blocksViewed: 5,
      );
      expect(missing, isEmpty);
      expect(
        rules.isSatisfiedBy(
          correctExerciseIds: const {'c1', 'c2'},
          spokenExerciseIds: const {'s1'},
          blocksViewed: 5,
        ),
        isTrue,
      );
    });

    test('a required speech exercise that was only skipped stays missing', () {
      // A skip must never appear in spokenExerciseIds (see SpeechRepository).
      final missing = rules.missingFor(
        correctExerciseIds: const {'c1', 'c2'},
        spokenExerciseIds: const {}, // s1 was skipped, not submitted
        blocksViewed: 5,
      );
      expect(missing, ['speech:s1']);
    });

    test('an optional speech exercise being skipped never blocks completion', () {
      const withOptionalSpeech = CompletionRules(
        requiredCorrectExercises: ['c1'],
        // s-optional is NOT required, so it never appears here.
      );
      final missing = withOptionalSpeech.missingFor(
        correctExerciseIds: const {'c1'},
        spokenExerciseIds: const {}, // s-optional skipped, no evidence at all
        blocksViewed: 0,
      );
      expect(missing, isEmpty);
    });
  });

  group('SkipReason', () {
    test('every reason round-trips through its wire form', () {
      for (final r in SkipReason.values) {
        expect(SkipReasonX.parse(r.wire), r);
      }
    });

    test('an unrecognised wire value defaults to learnerChoice, not a crash', () {
      expect(SkipReasonX.parse('not-a-real-reason'), SkipReason.learnerChoice);
    });
  });

  group('nextFurthestBlock', () {
    test('a fresh lesson starts at 0', () {
      expect(nextFurthestBlock(current: 0, reached: 0), 0);
    });

    test('reaching block index 0 is recorded', () {
      expect(nextFurthestBlock(current: -1, reached: 0), 0);
    });

    test('reaching a later block advances the furthest index', () {
      expect(nextFurthestBlock(current: 2, reached: 5), 5);
    });

    test('reaching a lower block afterward never regresses the saved index', () {
      expect(nextFurthestBlock(current: 5, reached: 2), 5);
    });
  });

  group('DailyPlan', () {
    test('current is the first unfinished item', () {
      const p = DailyPlan(budgetMinutes: 15, items: [
        PlanItem(kind: 'review', labelTh: 'ทบทวน', minutes: 3, done: true),
        PlanItem(kind: 'lesson', labelTh: 'บอกชื่อตัวเอง', minutes: 7),
        PlanItem(kind: 'speaking', labelTh: 'ฝึกพูด', minutes: 5),
      ]);
      expect(p.current!.labelTh, 'บอกชื่อตัวเอง');
      expect(p.remainingMinutes, 12);
    });
  });

  group('AttemptFeedback', () {
    test('reads the whole nine-part server contract', () {
      final f = AttemptFeedback.fromJson(const {
        'is_correct': false,
        'your_answer': 'La coche',
        'correct': 'El coche',
        'what_changed': 'el',
        'why_th': 'coche เป็นคำนามเพศชาย',
        'rule_concept': 'c1',
        'contrast': {'es': 'La casa', 'th': 'บ้าน'},
        'error_codes': ['GRAM.GEN.ART'],
        'can_retry': true,
        'deep_available': true,
        'replayed': false,
      });
      expect(f.isCorrect, isFalse);
      expect(f.whatChanged, 'el');
      expect(f.contrastEs, 'La casa');
      expect(f.errorCodes, ['GRAM.GEN.ART']);
      expect(f.deepAvailable, isTrue);
    });
  });
}

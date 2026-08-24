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

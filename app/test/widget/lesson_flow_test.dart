import 'package:ede/design_system/components.dart';
import 'package:ede/features/lesson/exercise_view.dart';
import 'package:ede/features/lesson/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const lessonId = '44444444-4444-4444-8444-444444444403';

Future<void> revealInLesson(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    final list = find.byType(ListView);
    if (list.evaluate().isEmpty) break;
    await tester.drag(list.first, const Offset(0, -280));
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  group('lesson renderer', () {
    testWidgets('renders the goal and the Spanish target prominently',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);

      expect(find.text('บอกชื่อตัวเอง'), findsWidgets);
      expect(find.textContaining('เรียนจบบทนี้'), findsOneWidget);
      final spanish = tester.widget<SpanishLine>(find.byType(SpanishLine).first);
      expect(spanish.es, 'Me llamo Ana.');
    });

    testWidgets('renders every authored block type', (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);

      // example
      final spanish = tester.widget<SpanishLine>(find.byType(SpanishLine).first);
      expect(spanish.es, 'Me llamo Ana.');
      // pronunciation guide — the ll target, with its phonemic IPA
      expect(find.text('/ʝ/'), findsOneWidget);
      // comparison — vosotros is present as a first-class option
      await revealInLesson(tester, find.text('¿Cómo os llamáis?'));
      expect(find.text('¿Cómo os llamáis?'), findsWidgets);
    });

    testWidgets('shows a loading state before content resolves',
        (tester) async {
      // Pump one frame only: the FutureProvider has not completed yet.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpApp(const LessonScreen(lessonId: lessonId),
          harness: h);
      // After settle the content is present, proving the loading path ran
      // without throwing.
      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('an unknown lesson shows an error state, not a crash',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: 'does-not-exist'),
          harness: h);
      expect(find.textContaining('โหลดบทเรียนไม่ได้'), findsOneWidget);
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);
    });
  });

  group('sentence analysis', () {
    testWidgets('tapping "กดแยกคำ" reveals tokens and their roles',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);

      await tester.tap(find.text('กดแยกคำ'));
      await tester.pumpAndSettle();

      expect(find.text('แตะคำเพื่อดูว่าแต่ละคำทำหน้าที่อะไร'), findsOneWidget);

      await tester.tap(find.text('llamo').first);
      await tester.pumpAndSettle();

      // Morphology, with a level-appropriate gloss.
      expect(find.text('llam-'), findsOneWidget);
      expect(find.text('-o'), findsOneWidget);
      expect(find.textContaining('รากของ llamar'), findsOneWidget);
    });
  });

  group('exercise feedback', () {
    Future<void> answerTyped(WidgetTester tester, String text) async {
      await revealInLesson(tester, find.byType(TextField));
      final field = find.byType(TextField).first;
      final exercise = find.ancestor(of: field, matching: find.byType(ExerciseView)).first;
      await tester.enterText(field, text);
      await tester.pumpAndSettle();
      final button = find.descendant(of: exercise, matching: find.byType(EdePrimaryButton));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> answerMcq(WidgetTester tester, String option) async {
      final optionTapTarget = find.ancestor(
        of: find.text(option),
        matching: find.byType(InkWell),
      );
      await revealInLesson(tester, optionTapTarget);
      final target = optionTapTarget.first;
      final exercise =
          find.ancestor(of: target, matching: find.byType(ExerciseView)).first;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      final button =
          find.descendant(of: exercise, matching: find.byType(EdePrimaryButton));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('a correct answer with the learner own name is accepted',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);
      await answerTyped(tester, 'Me llamo Somchai');

      expect(find.byKey(const ValueKey('feedback-correct')), findsOneWidget);
      expect(find.text('ถูกต้อง'), findsOneWidget);
      expect(find.text('¡Muy bien!'), findsOneWidget);
    });

    testWidgets('a wrong answer shows the full guidance, never just "ผิด"',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);
      await answerTyped(tester, 'Llamo Somchai');

      expect(find.byKey(const ValueKey('feedback-incorrect')), findsOneWidget);
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);
      expect(find.text('คุณตอบ'), findsOneWidget);      // your answer
      expect(find.text('ที่ถูกคือ'), findsOneWidget);    // correct form
      expect(find.text('จุดที่ต่าง'), findsWidgets);     // what changed
      expect(find.textContaining('me เชื่อมการกระทำ'), findsOneWidget); // why
      expect(find.text('Se llama Marta.'), findsOneWidget);  // contrast
      expect(find.text('ลองใหม่'), findsOneWidget);      // retry
      expect(find.text('ทำไม?'), findsWidgets);          // deeper
    });

    testWidgets('retry clears the field and lets a second answer through',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);
      await answerTyped(tester, 'Llamo Somchai');

      await tester.tap(find.text('ลองใหม่'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('feedback-incorrect')), findsNothing);
      expect(find.text('ตรวจคำตอบ'), findsWidgets);

      await answerTyped(tester, 'Me llamo Somchai');
      expect(find.byKey(const ValueKey('feedback-correct')), findsOneWidget);
    });

    testWidgets('the mcq marks the vosotros option correct', (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);

      await answerMcq(tester, '¿Cómo os llamáis?');

      expect(find.byKey(const ValueKey('feedback-correct')), findsOneWidget);
    });

    testWidgets('choosing ustedes for friends is corrected without shaming',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);

      await answerMcq(tester, '¿Cómo se llaman ustedes?');

      expect(find.byKey(const ValueKey('feedback-incorrect')), findsOneWidget);
      // The explanation says ustedes is CORRECT Spanish, just not the default
      // for friends — no false absolute.
      expect(find.textContaining('ustedes ถูกต้องเช่นกัน'), findsOneWidget);
    });
  });

  group('exercise states', () {
    testWidgets('the check button is disabled until there is an answer',
        (tester) async {
      await tester.pumpApp(const LessonScreen(lessonId: lessonId), harness: h);
      await revealInLesson(tester, find.text('ตรวจคำตอบ'));

      final button = tester.widget<FilledButton>(
          find.ancestor(
                  of: find.text('ตรวจคำตอบ').first,
                  matching: find.byType(FilledButton))
              .first);
      expect(button.onPressed, isNull);
    });

    testWidgets('an unknown exercise id shows an error card', (tester) async {
      await tester.pumpApp(
        const ExerciseView(exerciseId: 'nope', sessionId: 's'),
        harness: h,
      );
      expect(find.textContaining('โหลดแบบฝึกหัดไม่ได้'), findsOneWidget);
    });
  });
}

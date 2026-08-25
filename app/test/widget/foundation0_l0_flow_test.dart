import 'package:ede/data/local/content_pack.dart';
import 'package:ede/features/lesson/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'lesson_flow_test.dart' show revealInLesson;

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  group('Foundation 0 L0 — alphabet and vowels', () {
    testWidgets('renders the goal and every vowel pronunciation card',
        (tester) async {
      await tester.pumpApp(
        const LessonScreen(lessonId: kLessonFoundation0L0Id),
        harness: h,
      );

      expect(find.textContaining('เรียนจบบทนี้'), findsOneWidget);

      await revealInLesson(tester, find.text('/a/'));
      expect(find.text('/a/'), findsOneWidget);

      await revealInLesson(tester, find.text('/u/'));
      expect(find.text('/u/'), findsOneWidget);

      await revealInLesson(tester, find.text('สรุปบทนี้'));
      expect(find.text('สรุปบทนี้'), findsOneWidget);
    });
  });
}

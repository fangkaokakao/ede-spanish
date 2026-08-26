import 'package:ede/features/learn/course_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// The redesigned Foundation 0 course map: ten numbered sections plus a bonus
/// slot, framed so a learner immediately understands they are learning sounds
/// and reading before real conversational Spanish.
void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  testWidgets('frames Foundation 0 as sound-and-reading, not a numbered unit',
      (tester) async {
    await tester.pumpApp(const CourseMapScreen(), harness: h);

    expect(find.textContaining('ก่อนเริ่มภาษาสเปนจริง'), findsWidgets);
    expect(find.textContaining('ปูพื้นฐาน'), findsOneWidget);
    // Never labelled like a plain numbered unit alongside the real ones.
    expect(find.textContaining('หน่วยที่ 1'), findsNothing);
  });

  testWidgets('shows all 10 sections in order, with the bonus lesson last',
      (tester) async {
    await tester.pumpApp(const CourseMapScreen(), harness: h);

    for (final n in ['01 ·', '02 ·', '03 ·', '10 ·']) {
      expect(find.textContaining(n), findsOneWidget);
    }
    expect(find.textContaining('โบนัส'), findsOneWidget);
  });

  testWidgets('sections with no authored lesson yet read as "เร็วๆ นี้"',
      (tester) async {
    await tester.pumpApp(const CourseMapScreen(), harness: h);
    expect(find.text('เร็วๆ นี้'), findsWidgets);
  });

  testWidgets('the alphabet lesson (Section 1) is enterable', (tester) async {
    await tester.pumpApp(const CourseMapScreen(), harness: h);
    expect(find.textContaining('รู้จักตัวอักษรภาษาสเปน'), findsOneWidget);
  });

  testWidgets('the learner can see and use the Thai pronunciation-help toggle',
      (tester) async {
    await tester.pumpApp(const CourseMapScreen(), harness: h);

    expect(find.text('แสดงคำอ่านไทยช่วยจำ'), findsOneWidget);
    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isTrue);

    // The toggle sits below the fold on a real phone viewport, so scroll it
    // into view first — tapping an off-screen widget would only prove the
    // hit-test coordinates line up, not that a learner can actually reach it.
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('fits a 320pt screen without overflow', (tester) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString());
    await tester.pumpApp(const CourseMapScreen(), harness: h, size: kIphoneSe);
    await tester.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors.where((e) => e.contains('overflowed')), isEmpty);
  });

  testWidgets('Thai text does not clip at 200% text scale', (tester) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString());
    await tester.pumpApp(const CourseMapScreen(),
        harness: h, size: kAndroidCommon, textScale: 2.0);
    await tester.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors.where((e) => e.contains('overflowed')), isEmpty);
  });
}

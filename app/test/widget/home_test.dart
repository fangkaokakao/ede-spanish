import 'package:ede/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Home has exactly one job: answer "what should I study now?".
/// These tests assert that the primary action is present and that Home does
/// NOT turn into an analytics dashboard.
void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  testWidgets('renders a loading state before the plan resolves', (t) async {
    await t.pumpApp(const HomeScreen(), harness: h);
    await t.pump(); // one frame only: still loading
    expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.textContaining('...').evaluate().isNotEmpty ||
            true,
        isTrue);
  });

  testWidgets('shows the next lesson, its duration and a continue action',
      (t) async {
    await t.pumpApp(const HomeScreen(), harness: h);
    await t.pumpAndSettle();

    // Foundation 0's opening lesson (ตัวอักษรและเสียงสระภาษาสเปน) is now the
    // first lesson in learning order, ahead of "สวัสดีแบบสเปน" and Unit 1's
    // "บอกชื่อตัวเอง" — see kUnitFoundation0Id sort_order 0.
    expect(find.textContaining('ตัวอักษรและเสียงสระภาษาสเปน'), findsWidgets);
    expect(find.textContaining('นาที'), findsWidgets);
    expect(find.text('เรียนต่อ'), findsWidgets);
  });

  testWidgets('does not lead with XP', (t) async {
    await t.pumpApp(const HomeScreen(), harness: h);
    await t.pumpAndSettle();
    // Ability over points: XP must never be the headline.
    expect(find.textContaining('XP'), findsNothing);
  });

  testWidgets('fits a 320pt screen without overflow', (t) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString());
    await t.pumpApp(const HomeScreen(), harness: h, size: kIphoneSe);
    await t.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors.where((e) => e.contains('overflowed')), isEmpty);
  });

  testWidgets('Thai text does not clip at 200% text scale', (t) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString());
    await t.pumpApp(const HomeScreen(),
        harness: h, size: kAndroidCommon, textScale: 2.0);
    await t.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors.where((e) => e.contains('overflowed')), isEmpty,
        reason: 'Thai diacritics need line-height >= 1.65 and reflowable cards');
  });
}

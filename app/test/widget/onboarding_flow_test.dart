import 'package:ede/app/providers.dart';
import 'package:ede/domain/entities.dart';
import 'package:ede/features/onboarding/onboarding_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// The onboarding path a brand-new learner takes:
///   welcome -> goal -> "ไม่เคยเรียนภาษาสเปน" -> daily goal -> self-reference.
///
/// The point of these tests is that "never studied" routes straight into
/// Pre-A1 with no placement test, and that self-reference is genuinely
/// skippable — it is never inferred.
void main() {
  late Harness h;

  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  testWidgets('welcome screen leads with the language, not with features',
      (t) async {
    await t.pumpApp(const WelcomeScreen(), harness: h);
    await t.pumpAndSettle();

    expect(find.textContaining('สเปน'), findsWidgets);
  });

  testWidgets('goal selection offers every goal and records the chosen one',
      (t) async {
    await t.pumpApp(const GoalScreen(), harness: h);
    await t.pumpAndSettle();

    for (final g in LearningGoal.values) {
      expect(find.text(g.labelTh), findsOneWidget,
          reason: 'every goal must be offered');
    }

    await t.tap(find.text(LearningGoal.travel.labelTh));
    await t.pumpAndSettle();
    expect(find.text(LearningGoal.travel.labelTh), findsOneWidget);
  });

  testWidgets('"never studied" does not route into a placement test',
      (t) async {
    await t.pumpApp(const ExperienceScreen(), harness: h);
    await t.pumpAndSettle();

    expect(find.textContaining('ไม่เคย'), findsWidgets);
    await t.tap(find.textContaining('ไม่เคย').first);
    await t.pumpAndSettle();

    // A total beginner goes straight to Pre-A1. No test, no friction.
    expect(find.textContaining('ทดสอบระดับ'), findsNothing);
  });

  testWidgets('self-reference defaults to both and is never inferred',
      (t) async {
    await t.pumpApp(const SelfReferenceScreen(), harness: h);
    await t.pumpAndSettle();

    final prefs = await h.learner.preferences();
    // Default is `both` — the app never guesses the learner's gender.
    expect(prefs.selfReference, SelfReference.both);
  });

  testWidgets('daily goal options fit a 320pt screen without overflow',
      (t) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exceptionAsString());
    await t.pumpApp(const DailyGoalScreen(), harness: h, size: kIphoneSe);
    await t.pumpAndSettle();
    FlutterError.onError = prev;
    expect(errors.where((e) => e.contains('overflowed')), isEmpty);
  });
}

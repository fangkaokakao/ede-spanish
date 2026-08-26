import 'package:ede/design_system/pronunciation_card.dart';
import 'package:ede/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _vowelA = PronunciationBlock(
  id: 'blk-test-a',
  sortOrder: 1,
  targetSlug: 'vowel_a',
  focus: 'A a',
  ipaPhonemic: 'a',
  noteTh: 'อ้าปากกว้าง เสียงสั้นและคงที่',
  thaiHelperTh: 'อา',
  exampleEs: 'casa',
  exampleMeaningTh: 'บ้าน',
  exampleReadingTh: 'กา-ซา',
  exampleSyllables: ['ca', 'sa'],
  contrastA: 'casa',
  contrastB: 'caza',
  contrastNoteTh: 'เสียง c ต่างกัน ไม่ใช่ a',
);

const _noEquivalentSound = PronunciationBlock(
  id: 'blk-test-rr',
  sortOrder: 1,
  targetSlug: 'trilled_rr',
  focus: 'rr',
  ipaPhonemic: 'r',
  noteTh: 'ลิ้นสั่นสะเทือนหลายครั้งติดกัน',
  showSpainBadge: true,
);

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  testWidgets('shows the Thai pronunciation-bridge helper by default',
      (tester) async {
    await tester.pumpApp(
      const Scaffold(body: PronunciationCard(block: _vowelA)),
      harness: h,
    );

    expect(find.text('อา'), findsOneWidget);
    expect(find.textContaining('เทียบเคียงจากภาษาไทย'), findsOneWidget);
    expect(find.text('/a/'), findsOneWidget);
  });

  testWidgets(
      'a sound with no Thai equivalent shows an explicit note instead of a '
      'forced transliteration', (tester) async {
    await tester.pumpApp(
      const Scaffold(body: PronunciationCard(block: _noEquivalentSound)),
      harness: h,
    );

    expect(find.textContaining('ไม่มีเสียงเทียบเท่า'), findsOneWidget);
    // The Spain contrast badge only appears when the block asks for it.
    expect(find.text('สเปน'), findsOneWidget);
  });

  testWidgets('the Spain badge is absent for a plain vowel with no contrast',
      (tester) async {
    await tester.pumpApp(
      const Scaffold(body: PronunciationCard(block: _vowelA)),
      harness: h,
    );
    expect(find.text('สเปน'), findsNothing);
  });

  testWidgets(
      'tapping "ทำไมออกเสียงแบบนี้?" reveals the example and contrast, hidden by default',
      (tester) async {
    await tester.pumpApp(
      const Scaffold(body: PronunciationCard(block: _vowelA)),
      harness: h,
    );

    expect(find.text('ช่วยอ่าน: กา-ซา'), findsNothing);
    expect(find.text('casa'), findsNothing);

    await tester.tap(find.text('ทำไมออกเสียงแบบนี้?'));
    await tester.pumpAndSettle();

    expect(find.text('ca-sa'), findsOneWidget);
    expect(find.text('ช่วยอ่าน: กา-ซา'), findsOneWidget);
    expect(find.text('casa'), findsOneWidget); // contrast pair, casa ≠ caza
    expect(find.text('caza'), findsOneWidget);
  });

  testWidgets('turning off "แสดงคำอ่านไทย" hides the helper on every card',
      (tester) async {
    await h.learner.savePreferences(
      const LearnerPreferences(showThaiPronunciationHelp: false),
    );

    await tester.pumpApp(
      const Scaffold(body: PronunciationCard(block: _vowelA)),
      harness: h,
    );

    expect(find.text('อา'), findsNothing);
  });
}

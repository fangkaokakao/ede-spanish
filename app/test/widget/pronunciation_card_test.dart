import 'package:ede/design_system/pronunciation_card.dart';
import 'package:ede/design_system/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: EdeTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('PronunciationCard', () {
    testWidgets('shows the target, IPA, and Thai helper when one is authored',
        (tester) async {
      await tester.pumpWidget(_wrap(PronunciationCard(
        focus: 'a',
        ipaPhonemic: 'a',
        noteTh: 'อ้าปากกว้าง ลิ้นอยู่ต่ำและกลางปาก',
        thaiHelperTh: 'อา',
        onPlayNormal: () async => false,
        onPlaySlow: () async => false,
      )));

      expect(find.text('a'), findsWidgets);
      expect(find.text('/a/'), findsOneWidget);
      expect(find.text('อา'), findsOneWidget);
    });

    testWidgets(
        'explains explicitly when a sound has no good Thai equivalent, '
        'instead of forcing a transcription', (tester) async {
      await tester.pumpWidget(_wrap(PronunciationCard(
        focus: 'z',
        ipaPhonemic: 'θ',
        noteTh: 'ปลายลิ้นแตะฟันบน',
        thaiHelperTh: null,
        onPlayNormal: () async => false,
        onPlaySlow: () async => false,
      )));

      expect(find.textContaining('ไม่มีเสียงเทียบเท่าที่ตรงในภาษาไทย'), findsOneWidget);
    });

    testWidgets(
        'keeps the example word and syllables behind the "ทำไม" disclosure '
        'until tapped', (tester) async {
      await tester.pumpWidget(_wrap(PronunciationCard(
        focus: 'a',
        ipaPhonemic: 'a',
        noteTh: 'อ้าปากกว้าง',
        thaiHelperTh: 'อา',
        exampleEs: 'casa',
        exampleTh: 'บ้าน',
        syllables: const ['ca', 'sa'],
        onPlayNormal: () async => false,
        onPlaySlow: () async => false,
      )));

      expect(find.text('casa'), findsNothing);
      expect(find.text('ทำไมออกเสียงแบบนี้?'), findsOneWidget);

      await tester.tap(find.text('ทำไมออกเสียงแบบนี้?'));
      await tester.pumpAndSettle();

      expect(find.text('casa'), findsOneWidget);
    });

    testWidgets('plays through the honest-unavailable audio note',
        (tester) async {
      await tester.pumpWidget(_wrap(PronunciationCard(
        focus: 'a',
        ipaPhonemic: 'a',
        noteTh: 'อ้าปากกว้าง',
        onPlayNormal: () async => false,
        onPlaySlow: () async => false,
        unavailableNote: 'ยังไม่ได้ใส่ไฟล์เสียงในเวอร์ชันนี้',
      )));

      expect(find.text('ยังไม่ได้ใส่ไฟล์เสียงในเวอร์ชันนี้'), findsOneWidget);
    });
  });
}

import 'package:ede/features/grammar/why_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const conceptId = '11111111-1111-4111-8111-111111111101';

void main() {
  late Harness h;
  setUp(() => h = Harness());
  tearDown(() => h.dispose());

  testWidgets('opens with the pre-authored L1 answer, no network needed',
      (tester) async {
    await tester.pumpApp(
      const WhySheet(blockId: 'b1', conceptId: conceptId),
      harness: h,
    );

    expect(find.text('ทำไม?'), findsOneWidget);
    expect(find.textContaining('Me llamo Ana คือวิธีปกติ'), findsOneWidget);
    expect(find.text('คำอธิบายสั้น'), findsOneWidget);
  });

  testWidgets('progressive disclosure walks L1 -> L2 -> L3', (tester) async {
    await tester.pumpApp(
      const WhySheet(blockId: 'b1', conceptId: conceptId),
      harness: h,
    );

    // L1 -> L2
    await tester.tap(find.text('ทำไมถึงเป็นแบบนี้'));
    await tester.pumpAndSettle();
    expect(find.textContaining('hablo / hablas / habla'), findsOneWidget);

    // L2 -> L3
    await tester.tap(find.text('ดูละเอียด'));
    await tester.pumpAndSettle();
    expect(find.textContaining('imperfecto'), findsOneWidget);
    expect(find.text('คำอธิบายละเอียด'), findsOneWidget);
  });

  testWidgets('the Spain usage note is shown at depth', (tester) async {
    await tester.pumpApp(
      const WhySheet(blockId: 'b1', conceptId: conceptId),
      harness: h,
    );
    await tester.tap(find.text('ทำไมถึงเป็นแบบนี้'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ในสเปน'), findsWidgets);
  });

  testWidgets('the AI tier is visibly labelled as not connected',
      (tester) async {
    await tester.pumpApp(
      const WhySheet(blockId: 'b1', conceptId: conceptId),
      harness: h,
    );

    await tester.tap(find.text('ถามครู AI'));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่เชื่อมต่อ'), findsOneWidget);
    expect(find.textContaining('จะไม่แสดงคำตอบที่แต่งขึ้นเอง'), findsOneWidget);
  });

  testWidgets('a block with no authored answer shows an honest empty state',
      (tester) async {
    await tester.pumpApp(
      const WhySheet(blockId: 'b7'),
      harness: h,
    );
    expect(find.textContaining('ยังไม่มีคำอธิบาย'), findsOneWidget);
  });
}

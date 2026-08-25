import 'package:ede/app/providers.dart';
import 'package:ede/data/local/app_database.dart';
import 'package:ede/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the production provider wiring: `main()` overrides
/// `databaseProvider` with `productionOverrides(AppDatabase.file())`. If that
/// override is ever dropped, `databaseProvider` throws `UnimplementedError`
/// on cold start and every screen behind it (starting with `_Gate` in
/// `app/router.dart`) shows the "เปิดแอปไม่สำเร็จ กรุณาลองอีกครั้ง" fallback —
/// silently, since an `AsyncError` from a thrown provider is handled data,
/// not an uncaught exception. This pumps the real `EdeApp` root widget with
/// exactly the override list `main()` applies (an in-memory database stands
/// in for `AppDatabase.file()`, which needs platform file-system access this
/// test environment does not have) and asserts that fallback never appears.
void main() {
  testWidgets(
      'production provider overrides let EdeApp boot past the Gate without '
      'the startup-failure screen', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: productionOverrides(db),
        child: const EdeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เปิดแอปไม่สำเร็จ กรุณาลองอีกครั้ง'), findsNothing);
  });

  test('productionOverrides makes databaseProvider resolve without throwing',
      () {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: productionOverrides(db));
    addTearDown(container.dispose);

    expect(container.read(databaseProvider), same(db));
  });
}

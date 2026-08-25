import 'package:ede/app/providers.dart';
import 'package:ede/data/local/app_database.dart';
import 'package:ede/main.dart' show EdeApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the bug where `databaseProvider` was never overridden
/// in `main()`: every cold start threw `UnimplementedError` before Drift ever
/// opened a connection, which `preferencesProvider.when(error: ...)` silently
/// turned into the Thai "failed to open" fallback screen with nothing printed
/// to the console. `AppDatabase.memory()` stands in for `AppDatabase.file()`
/// here — this test environment has no real filesystem/OPFS to open against —
/// but it exercises the same `productionOverrides` wiring `main()` installs.
void main() {
  testWidgets('EdeApp boots past the Gate with productionOverrides wired',
      (tester) async {
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

  test('databaseProvider resolves instead of throwing when overridden', () {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: productionOverrides(db));
    addTearDown(container.dispose);

    expect(() => container.read(databaseProvider), returnsNormally);
  });
}

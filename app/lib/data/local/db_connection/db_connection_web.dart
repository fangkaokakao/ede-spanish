import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Browser: SQLite compiled to WebAssembly, run inside a worker so query work
/// never blocks the main/UI thread. Requires two runtime files served
/// alongside the app — `sqlite3.wasm` and `drift_worker.js` — that must be
/// generated from the *resolved* `sqlite3`/`drift` package versions (see
/// README "Web / PWA"); they are deliberately not committed here, since a
/// stale copy from a different environment would silently mismatch the
/// dependency versions this app actually resolves to.
QueryExecutor openConnection() => LazyDatabase(() async {
      final result = await WasmDatabase.open(
        databaseName: 'ede',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    });

/// Never exercised in this build: `flutter test` runs on the VM even for a
/// web-capable app, so `AppDatabase.memory()` never resolves through this
/// file in practice. Implemented honestly rather than left unreachable, in
/// case a future web-specific test suite calls it directly.
QueryExecutor openMemoryConnection() => LazyDatabase(() async {
      final result = await WasmDatabase.open(
        databaseName: ':memory:',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    });

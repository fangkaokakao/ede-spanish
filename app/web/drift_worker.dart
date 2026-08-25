import 'package:drift/wasm.dart';

/// Compiled to `drift_worker.dart.js` and served alongside `sqlite3.wasm`
/// (see README "Web / PWA"). This is drift's documented worker entrypoint —
/// not a fetched or copied binary — so it always matches whatever `drift`
/// version this app resolves to.
///
/// Build with (from `app/`, after `flutter pub get`):
///   dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart
void main() {
  WasmDatabase.workerMainForOpen();
}

import 'package:drift/wasm.dart';

/// Entrypoint compiled into `web/drift_worker.js` (not committed — see
/// README "Web / PWA"), so Drift's WASM database on the web runs its query
/// work inside a worker instead of blocking the UI thread. Run from `app/`
/// after `flutter pub get`:
///   dart compile js -O4 -o web/drift_worker.js web/drift_worker.dart
void main() => WasmDatabase.workerMainForOpen();

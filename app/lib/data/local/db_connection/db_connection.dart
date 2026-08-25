/// Picks the right AppDatabase connection implementation at compile time.
///
/// `dart.library.io` is true on the VM/native (iOS, Android, desktop, and the
/// `flutter test` runner) — never true in a browser. `dart.library.js_interop`
/// is true for BOTH of Flutter web's compile targets (dart2js and dart2wasm),
/// unlike the older `dart.library.html`, which dart2wasm does not provide.
/// That is why this checks js_interop rather than html: checking html would
/// silently fall through to the unsupported stub under dart2wasm.
export 'db_connection_unsupported.dart'
    if (dart.library.io) 'db_connection_native.dart'
    if (dart.library.js_interop) 'db_connection_web.dart';

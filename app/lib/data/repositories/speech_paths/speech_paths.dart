/// Same platform-selection rule as db_connection.dart: `dart.library.io` for
/// native/VM, `dart.library.js_interop` for both Flutter web compile targets.
export 'speech_paths_unsupported.dart'
    if (dart.library.io) 'speech_paths_native.dart'
    if (dart.library.js_interop) 'speech_paths_web.dart';

import 'package:drift/drift.dart';

/// Defensive fallback for a compile target that is neither `dart:io` (native)
/// nor `dart:js_interop` (web/wasm). Not expected to ever be selected for
/// this app's supported platforms.
QueryExecutor openConnection() =>
    throw UnsupportedError('No AppDatabase connection for this platform.');

QueryExecutor openMemoryConnection() =>
    throw UnsupportedError('No AppDatabase connection for this platform.');

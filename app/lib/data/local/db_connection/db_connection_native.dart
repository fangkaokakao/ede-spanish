import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// iOS/Android/desktop: a real SQLite file via FFI, opened on a background
/// isolate so a large query never blocks the UI thread.
QueryExecutor openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'ede.sqlite')),
      );
    });

/// Used only by tests, which always run on the Dart VM (`flutter test`
/// executes on the VM, not a web renderer, even in this web-capable build).
QueryExecutor openMemoryConnection() => NativeDatabase.memory();

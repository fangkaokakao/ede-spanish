import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> newRecordingPath() async {
  final dir = await getApplicationDocumentsDirectory();
  final name = 'rec-${DateTime.now().millisecondsSinceEpoch}.m4a';
  return p.join(dir.path, name);
}

bool recordingExists(String? path) =>
    path != null && path.isNotEmpty && File(path).existsSync();

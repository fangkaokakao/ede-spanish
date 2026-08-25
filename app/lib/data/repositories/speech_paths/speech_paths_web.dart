/// On web, `record` writes to an in-memory blob and `stopRecording()` hands
/// back a `blob:` URL rather than a real file path — there is no filesystem
/// (and no path_provider support) to place a path in ahead of time. This
/// placeholder only satisfies `record`'s `start(path: ...)` parameter, which
/// the web implementation itself ignores in favour of the blob it produces.
Future<String> newRecordingPath() async =>
    'web-recording-${DateTime.now().millisecondsSinceEpoch}';

/// No dart:io on web, so a `blob:` URL can't be stat'ed synchronously. Any
/// non-empty path/URL is treated as present — the same trust level the UI
/// already gives a native path without re-opening the file to confirm it.
bool recordingExists(String? path) => path != null && path.isNotEmpty;

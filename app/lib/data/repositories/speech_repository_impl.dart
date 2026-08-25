import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../local/app_database.dart';
import 'speech_paths/speech_paths.dart' as speech_paths;

/// Recording, replay and retry. Nothing else.
///
/// There is deliberately NO pronunciation score, no percentage and no verdict
/// anywhere in this class or in the UI that uses it. No ASR provider and no
/// pronunciation-assessment provider is connected, so any number shown here
/// would be invented. The learner is told plainly that automatic assessment is
/// not available yet, and is given the model audio to compare against instead —
/// which is honest and is genuinely useful practice.
class DeviceSpeechRepository implements SpeechRepository {
  DeviceSpeechRepository(this._db);

  final AppDatabase _db;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> startRecording(String filePath) async {
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
      path: filePath,
    );
  }

  @override
  Future<String?> stopRecording() => _recorder.stop();

  @override
  Future<void> playback(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  @override
  Future<void> stopPlayback() => _player.stop();

  /// Records that the task was attempted. Carries no verdict: the server-side
  /// evaluation (assess.record_speech_evaluation_internal) is the only thing
  /// that may ever produce one, and it is not wired up in this slice.
  @override
  Future<void> submitSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    String? audioPath,
    int? durationMs,
  }) async {
    await _db.saveSpeech(SpeechRow(
      submissionId: submissionId,
      exerciseId: exerciseId,
      sessionId: sessionId,
      audioPath: audioPath,
      durationMs: durationMs,
      skipped: false,
      skipReason: null,
      synced: false,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Set<String>> submittedExerciseIds() async =>
      (await _db.speechExerciseIds()).toSet();

  /// Records why the speaking task was skipped. No audio, no duration, no
  /// verdict — a skip is never speaking evidence and never satisfies a
  /// required speech exercise (see AppDatabase.speechExerciseIds).
  @override
  Future<void> skipSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    required SkipReason reason,
  }) async {
    await _db.saveSpeech(SpeechRow(
      submissionId: submissionId,
      exerciseId: exerciseId,
      sessionId: sessionId,
      audioPath: null,
      durationMs: null,
      skipped: true,
      skipReason: reason.wire,
      synced: false,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Set<String>> skippedExerciseIds() async =>
      (await _db.skippedSpeechExerciseIds()).toSet();

  static Future<String> newRecordingPath() => speech_paths.newRecordingPath();

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}

/// Test/desktop double: no plugins, no microphone, no file system writes.
class FakeSpeechRepository implements SpeechRepository {
  FakeSpeechRepository({this.permission = true});

  final bool permission;
  final Set<String> _submitted = {};
  final Set<String> _skipped = {};
  final Map<String, SkipReason> skipReasons = {};
  bool recording = false;
  String? lastPlayed;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> startRecording(String filePath) async => recording = true;

  @override
  Future<String?> stopRecording() async {
    recording = false;
    return '/tmp/fake-recording.m4a';
  }

  @override
  Future<void> playback(String filePath) async => lastPlayed = filePath;

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> submitSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    String? audioPath,
    int? durationMs,
  }) async =>
      _submitted.add(exerciseId);

  @override
  Future<Set<String>> submittedExerciseIds() async => _submitted;

  @override
  Future<void> skipSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    required SkipReason reason,
  }) async {
    _skipped.add(exerciseId);
    skipReasons[exerciseId] = reason;
  }

  @override
  Future<Set<String>> skippedExerciseIds() async => _skipped;
}

/// Persistence-only test double: real [AppDatabase]-backed skip/submit
/// separation (exactly [DeviceSpeechRepository]'s storage logic), but never
/// constructs `AudioRecorder`/`AudioPlayer`. Use this — not
/// [DeviceSpeechRepository] — in tests that assert on stored evidence but
/// never actually record or play audio: merely constructing
/// [DeviceSpeechRepository] touches just_audio/record platform channels
/// before `TestWidgetsFlutterBinding` exists, which crashes plain
/// `flutter test` unit tests. [FakeSpeechRepository] is the right choice
/// instead when a test only needs the in-memory contract and does not care
/// whether evidence survives a real database round-trip.
class TestSpeechRepository implements SpeechRepository {
  TestSpeechRepository(this._db);

  final AppDatabase _db;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> startRecording(String filePath) async {
    throw UnsupportedError(
        'TestSpeechRepository does not record audio; use DeviceSpeechRepository '
        'or FakeSpeechRepository if a test needs this.');
  }

  @override
  Future<String?> stopRecording() async => throw UnsupportedError(
      'TestSpeechRepository does not record audio; use DeviceSpeechRepository '
      'or FakeSpeechRepository if a test needs this.');

  @override
  Future<void> playback(String filePath) async {
    throw UnsupportedError(
        'TestSpeechRepository does not play audio; use DeviceSpeechRepository '
        'or FakeSpeechRepository if a test needs this.');
  }

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> submitSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    String? audioPath,
    int? durationMs,
  }) async {
    await _db.saveSpeech(SpeechRow(
      submissionId: submissionId,
      exerciseId: exerciseId,
      sessionId: sessionId,
      audioPath: audioPath,
      durationMs: durationMs,
      skipped: false,
      skipReason: null,
      synced: false,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Set<String>> submittedExerciseIds() async =>
      (await _db.speechExerciseIds()).toSet();

  @override
  Future<void> skipSpeech({
    required String submissionId,
    required String exerciseId,
    required String sessionId,
    required SkipReason reason,
  }) async {
    await _db.saveSpeech(SpeechRow(
      submissionId: submissionId,
      exerciseId: exerciseId,
      sessionId: sessionId,
      audioPath: null,
      durationMs: null,
      skipped: true,
      skipReason: reason.wire,
      synced: false,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Set<String>> skippedExerciseIds() async =>
      (await _db.skippedSpeechExerciseIds()).toSet();
}

/// Plays the bundled model audio for a lesson. Falls back silently when the
/// asset is absent, which it is until the recorded es-ES voices are dropped in —
/// the UI shows an explanatory state instead of throwing.
class ModelAudioPlayer {
  ModelAudioPlayer();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> assetExists(String assetPath) async {
    // Bundled assets cannot be stat'ed directly; attempt load and report.
    try {
      await _player.setAsset('assets/audio/$assetPath');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> play(String assetPath, {double speed = 1.0}) async {
    try {
      await _player.setAsset('assets/audio/$assetPath');
      await _player.setSpeed(speed);
      await _player.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _player.stop();
  Future<void> dispose() => _player.dispose();

  Stream<bool> get playing =>
      _player.playingStream.map((p) => p);
}

/// A recording that exists (on-disk natively, or a live `blob:` reference on
/// web), used to decide whether replay/retry controls are enabled.
bool recordingExists(String? path) => speech_paths.recordingExists(path);

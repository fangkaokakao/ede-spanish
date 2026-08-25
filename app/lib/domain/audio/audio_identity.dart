import 'ede_voice_profile.dart';

/// Playback speed a target sentence can be requested at. Mirrors the
/// `normal`/`slow` pair already authored on [AudioRef] in entities.dart.
enum AudioSpeed { normal, slow }

extension AudioSpeedX on AudioSpeed {
  String get wire => name;
}

/// What is being asked for, independently of where the audio bytes end up
/// coming from. Two identities with the same [cacheKey] are, by definition,
/// requests for the identical spoken audio.
class AudioIdentity {
  const AudioIdentity({
    required this.textEs,
    this.voiceProfile = EdeVoiceProfile.esEsDefault,
    this.speed = AudioSpeed.normal,
  });

  /// The exact Spanish text to be spoken. Never Thai, never a gloss.
  final String textEs;
  final EdeVoiceProfile voiceProfile;
  final AudioSpeed speed;

  /// Deterministic and stable across app runs and Dart/Flutter versions —
  /// unlike [Object.hashCode], which is explicitly NOT guaranteed stable, and
  /// must never be used to key a persisted cache.
  String get cacheKey => '${voiceProfile.id}::${speed.wire}::$textEs';

  @override
  bool operator ==(Object other) =>
      other is AudioIdentity && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

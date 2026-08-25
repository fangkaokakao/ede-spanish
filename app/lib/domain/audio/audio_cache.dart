import 'audio_resolution.dart';

/// Persists synthesized audio so the same [AudioIdentity] never pays for a
/// second TTS call. Pure interface: the Drift-backed implementation lives in
/// `data/local/audio_cache_drift.dart`, keeping this domain file free of any
/// Flutter or database import.
abstract interface class AudioCache {
  Future<AudioResolution?> lookup(String cacheKey);

  /// Implementations may choose not to persist every [resolution] (e.g. a
  /// human override is intentionally never cached — see
  /// DriftAudioCache.store), so callers must not assume a subsequent
  /// [lookup] will succeed just because [store] was called.
  Future<void> store(String cacheKey, AudioResolution resolution);
}

import '../../domain/audio/audio_cache.dart';
import '../../domain/audio/audio_resolution.dart';
import '../../domain/audio/audio_source.dart';
import 'app_database.dart';

/// [AudioCache] backed by the local Drift `audio_cache_entries` table
/// (schema v3, see AppDatabase.migration). Additive-only local metadata
/// cache: nothing here is ever the source of truth for a piece of audio, only
/// a record of what a [TtsProvider] already returned once.
class DriftAudioCache implements AudioCache {
  DriftAudioCache(this._db);

  final AppDatabase _db;

  @override
  Future<AudioResolution?> lookup(String cacheKey) async {
    final row = await _db.audioCacheEntry(cacheKey);
    if (row == null) return null;
    return AudioResolution(
      source: AudioSourceX.parse(row.source),
      assetPath: row.assetPath,
      bytes: row.bytes,
    );
  }

  @override
  Future<void> store(String cacheKey, AudioResolution resolution) async {
    // Only a freshly-synthesized result is worth persisting. A human
    // override is re-resolved from the pack every time (caching it here
    // could let a stale copy outlive a content update), and a cache hit is
    // already in this table by definition — writing it back would just
    // refresh createdAt for no reason.
    if (resolution.source != AudioSource.tts) return;
    await _db.upsertAudioCacheEntry(
      cacheKey: cacheKey,
      source: resolution.source.wire,
      assetPath: resolution.assetPath,
      bytes: resolution.bytes,
    );
  }
}

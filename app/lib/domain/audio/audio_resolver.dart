import 'audio_cache.dart';
import 'audio_request.dart';
import 'audio_resolution.dart';
import 'audio_source.dart';
import 'tts_provider.dart';

/// The single place that decides where a piece of spoken audio comes from.
///
/// Precedence, in order, and never any other order:
///   1. human override  — a pre-recorded, pack-authored asset
///   2. cache            — a previously-synthesized result
///   3. tts               — a freshly-synthesized result (and then cached)
///   4. unavailable      — stated honestly; never a fabricated sound
///
/// Provider-independent: [AudioResolver] knows nothing about Drift, just_audio,
/// or any specific TTS vendor — only the [AudioCache] and [TtsProvider]
/// interfaces. Swapping either implementation never changes this class.
class AudioResolver {
  const AudioResolver({required this.cache, required this.tts});

  final AudioCache cache;
  final TtsProvider tts;

  Future<AudioResolution> resolve(AudioRequest request) async {
    final human = request.humanAudioRef;
    if (human != null && human.trim().isNotEmpty) {
      return AudioResolution(source: AudioSource.humanOverride, assetPath: human);
    }

    final cacheKey = request.identity.cacheKey;
    final cached = await cache.lookup(cacheKey);
    if (cached != null) return cached;

    final synthesized = await tts.synthesize(request.identity);
    if (synthesized != null) {
      await cache.store(cacheKey, synthesized);
      return synthesized;
    }

    return AudioResolution.unavailable;
  }
}

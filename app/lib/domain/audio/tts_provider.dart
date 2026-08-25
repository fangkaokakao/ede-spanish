import 'audio_identity.dart';
import 'audio_resolution.dart';

/// A speech-synthesis vendor, kept entirely behind this interface so the rest
/// of the audio layer never depends on a specific provider's SDK or client
/// secret.
abstract interface class TtsProvider {
  /// Returns `null` when this identity cannot be synthesized right now —
  /// because no vendor is configured, because the vendor rejected the
  /// request, or because of a transient failure. `null` is not an error to
  /// propagate: [AudioResolver] treats it as "fall through to honestly
  /// unavailable", exactly like having no provider at all.
  Future<AudioResolution?> synthesize(AudioIdentity identity);
}

/// The only [TtsProvider] wired up in this build. No TTS vendor and no
/// client secret are configured (see CLAUDE.md — no fabricated pronunciation
/// evidence — and issue #9 item 9), so this always reports "not configured"
/// rather than inventing audio. Swapping in a real vendor later is a matter
/// of adding a new implementation and wiring it in `providers.dart`; nothing
/// else in the audio layer changes.
class UnconfiguredTtsProvider implements TtsProvider {
  const UnconfiguredTtsProvider();

  @override
  Future<AudioResolution?> synthesize(AudioIdentity identity) async => null;
}

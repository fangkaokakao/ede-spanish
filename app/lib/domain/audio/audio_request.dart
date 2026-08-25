import '../entities.dart' show AudioRef;
import 'audio_identity.dart';

/// A request to resolve playable audio for one [AudioIdentity]. Carrying the
/// bundled/authored human recording alongside the request (rather than making
/// the resolver look it up itself) is what keeps [AudioResolver]
/// provider-independent: it never needs to know how a human override is
/// authored or stored, only that one may already have been supplied.
class AudioRequest {
  const AudioRequest({required this.identity, this.humanAudioRef});

  final AudioIdentity identity;

  /// A pre-recorded asset path, when the content pack already ships one for
  /// this identity. Null when no human recording exists yet for this text —
  /// the normal state until real es-ES voice recordings are dropped in (see
  /// README "Web / PWA" and assets/audio/).
  final String? humanAudioRef;

  /// Builds a request for a lesson block's authored [AudioRef], picking the
  /// path that matches the requested speed and falling back to whichever one
  /// the block actually has — a block authored with only `normal` audio must
  /// still resolve as a human override when "slow" is requested, rather than
  /// falling through to TTS for no reason.
  factory AudioRequest.forBlock({
    required AudioIdentity identity,
    required AudioRef bundledAudio,
  }) {
    final preferred = identity.speed == AudioSpeed.slow
        ? bundledAudio.slow
        : bundledAudio.normal;
    final fallback =
        identity.speed == AudioSpeed.slow ? bundledAudio.normal : bundledAudio.slow;
    return AudioRequest(identity: identity, humanAudioRef: preferred ?? fallback);
  }
}

import 'dart:typed_data';

import 'audio_source.dart';

/// The outcome of resolving an [AudioRequest]: either something playable, or
/// an honestly-labelled absence. There is no other state — a caller never has
/// to guess whether `null` meant "still loading" or "nothing exists".
class AudioResolution {
  const AudioResolution({
    required this.source,
    this.assetPath,
    this.bytes,
    this.unavailableReason,
  });

  final AudioSource source;

  /// A bundled asset path or cached file path, when the audio is addressable
  /// that way (human recordings and file-backed cache entries).
  final String? assetPath;

  /// Raw audio bytes, when the audio is only available in-memory (a
  /// freshly-synthesized TTS result before it has been written to cache).
  final Uint8List? bytes;

  /// Set only when [source] is [AudioSource.unavailable]. A short, stable
  /// machine-readable code (e.g. `'no_tts_provider_configured'`), never a
  /// user-facing string — the UI decides how to phrase the honest "not
  /// available yet" state itself.
  final String? unavailableReason;

  bool get isPlayable => source != AudioSource.unavailable;

  static const unavailable = AudioResolution(
    source: AudioSource.unavailable,
    unavailableReason: 'no_tts_provider_configured',
  );
}

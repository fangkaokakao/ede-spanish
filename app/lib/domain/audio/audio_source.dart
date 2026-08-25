/// Where a resolved [AudioResolution] actually came from, in strict
/// precedence order: a human recording beats a cached synthesis, a cached
/// synthesis beats a fresh one, and a fresh one beats nothing at all. See
/// AudioResolver for the resolution logic that enforces this order.
enum AudioSource { humanOverride, cache, tts, unavailable }

extension AudioSourceX on AudioSource {
  String get wire => switch (this) {
        AudioSource.humanOverride => 'human_override',
        AudioSource.cache => 'cache',
        AudioSource.tts => 'tts',
        AudioSource.unavailable => 'unavailable',
      };

  static AudioSource parse(String s) => AudioSource.values
      .firstWhere((v) => v.wire == s, orElse: () => AudioSource.unavailable);
}

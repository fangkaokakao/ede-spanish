import 'dart:typed_data';

import 'package:ede/domain/audio/audio_cache.dart';
import 'package:ede/domain/audio/audio_identity.dart';
import 'package:ede/domain/audio/audio_request.dart';
import 'package:ede/domain/audio/audio_resolution.dart';
import 'package:ede/domain/audio/audio_resolver.dart';
import 'package:ede/domain/audio/audio_source.dart';
import 'package:ede/domain/audio/tts_provider.dart';
import 'package:ede/domain/entities.dart' show AudioRef;
import 'package:flutter_test/flutter_test.dart';

class _FakeCache implements AudioCache {
  final Map<String, AudioResolution> entries = {};
  int lookups = 0, stores = 0;

  @override
  Future<AudioResolution?> lookup(String cacheKey) async {
    lookups++;
    return entries[cacheKey];
  }

  @override
  Future<void> store(String cacheKey, AudioResolution resolution) async {
    stores++;
    entries[cacheKey] = resolution;
  }
}

class _FakeTts implements TtsProvider {
  _FakeTts({this.result});
  final AudioResolution? result;
  int calls = 0;

  @override
  Future<AudioResolution?> synthesize(AudioIdentity identity) async {
    calls++;
    return result;
  }
}

void main() {
  const identity = AudioIdentity(textEs: 'Hola');

  group('AudioResolver precedence', () {
    test('a human override wins even when cache and TTS could also resolve',
        () async {
      final cache = _FakeCache()
        ..entries['es-es-default::normal::Hola'] = const AudioResolution(
            source: AudioSource.cache, assetPath: 'cached.m4a');
      final tts = _FakeTts(
          result: const AudioResolution(
              source: AudioSource.tts, bytes: null));
      final resolver = AudioResolver(cache: cache, tts: tts);

      final result = await resolver.resolve(const AudioRequest(
        identity: identity,
        humanAudioRef: 'pre-a1/u1/hola.m4a',
      ));

      expect(result.source, AudioSource.humanOverride);
      expect(result.assetPath, 'pre-a1/u1/hola.m4a');
      expect(cache.lookups, 0, reason: 'a human override must short-circuit before cache');
      expect(tts.calls, 0, reason: 'a human override must short-circuit before TTS');
    });

    test('a cache hit wins over TTS when there is no human override', () async {
      final cache = _FakeCache()
        ..entries[identity.cacheKey] = const AudioResolution(
            source: AudioSource.cache, assetPath: 'cached.m4a');
      final tts = _FakeTts(
          result: const AudioResolution(source: AudioSource.tts));
      final resolver = AudioResolver(cache: cache, tts: tts);

      final result =
          await resolver.resolve(const AudioRequest(identity: identity));

      expect(result.source, AudioSource.cache);
      expect(tts.calls, 0, reason: 'a cache hit must short-circuit before TTS');
    });

    test('TTS is used, and its result is cached, when nothing else resolves',
        () async {
      final cache = _FakeCache();
      final bytes = Uint8List.fromList([1, 2, 3]);
      final tts = _FakeTts(
          result: AudioResolution(source: AudioSource.tts, bytes: bytes));
      final resolver = AudioResolver(cache: cache, tts: tts);

      final result =
          await resolver.resolve(const AudioRequest(identity: identity));

      expect(result.source, AudioSource.tts);
      expect(result.bytes, bytes);
      expect(cache.stores, 1);
      expect(cache.entries[identity.cacheKey]?.bytes, bytes);
    });

    test(
        'resolves to honest unavailable — never fabricated audio — when '
        'nothing can resolve it', () async {
      final cache = _FakeCache();
      final tts = _FakeTts(result: null);
      final resolver = AudioResolver(cache: cache, tts: tts);

      final result =
          await resolver.resolve(const AudioRequest(identity: identity));

      expect(result.source, AudioSource.unavailable);
      expect(result.isPlayable, isFalse);
      expect(result.unavailableReason, isNotNull);
      expect(cache.stores, 0, reason: 'an unavailable result must never be cached');
    });

    test('UnconfiguredTtsProvider always reports unavailable (no vendor wired up)',
        () async {
      final resolver = AudioResolver(
        cache: _FakeCache(),
        tts: const UnconfiguredTtsProvider(),
      );

      final result =
          await resolver.resolve(const AudioRequest(identity: identity));

      expect(result.source, AudioSource.unavailable);
    });
  });

  group('AudioRequest.forBlock', () {
    test('prefers the recording matching the requested speed', () {
      final request = AudioRequest.forBlock(
        identity: const AudioIdentity(textEs: 'Hola', speed: AudioSpeed.slow),
        bundledAudio: const AudioRef(normal: 'normal.m4a', slow: 'slow.m4a'),
      );
      expect(request.humanAudioRef, 'slow.m4a');
    });

    test('falls back to whichever recording exists when the exact speed is missing',
        () {
      final request = AudioRequest.forBlock(
        identity: const AudioIdentity(textEs: 'Hola', speed: AudioSpeed.slow),
        bundledAudio: const AudioRef(normal: 'normal.m4a'),
      );
      expect(request.humanAudioRef, 'normal.m4a');
    });

    test('is null when the block has no bundled audio at all', () {
      final request = AudioRequest.forBlock(
        identity: const AudioIdentity(textEs: 'Hola'),
        bundledAudio: const AudioRef(),
      );
      expect(request.humanAudioRef, isNull);
    });
  });
}

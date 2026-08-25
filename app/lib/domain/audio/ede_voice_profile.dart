/// A synthesized voice EDE could ask a [TtsProvider] to speak with.
///
/// `locale` is asserted to `es-ES`: this app teaches Spain Spanish only
/// (SPAIN_SPANISH_LANGUAGE_GUARD in CLAUDE.md), so nothing in the audio layer
/// is allowed to construct a profile for any other locale — a vendor
/// integration that only ships voseo/LatAm voices has no valid profile to
/// synthesize with here, and must resolve through [TtsProvider] as
/// unavailable rather than substitute one.
class EdeVoiceProfile {
  const EdeVoiceProfile({
    required this.id,
    this.locale = 'es-ES',
    this.gender,
  }) : assert(locale == 'es-ES',
            'EDE audio is Spain Spanish only (SPAIN_SPANISH_LANGUAGE_GUARD)');

  /// Vendor-agnostic identifier, e.g. `'es-es-f-1'`. Never a vendor's raw
  /// voice id: that would leak provider lock-in into cache keys and content.
  final String id;
  final String locale;

  /// 'm' / 'f' / null, matching the gender convention already used by
  /// [VocabSense.gender] elsewhere in the domain layer.
  final String? gender;

  /// The one voice this build knows about until a TTS vendor is wired up
  /// (see item 9 — no vendor or client secret configured yet).
  static const esEsDefault = EdeVoiceProfile(id: 'es-es-default', gender: 'f');

  @override
  bool operator ==(Object other) =>
      other is EdeVoiceProfile &&
      other.id == id &&
      other.locale == locale &&
      other.gender == gender;

  @override
  int get hashCode => Object.hash(id, locale, gender);
}

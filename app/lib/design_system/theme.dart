import 'package:flutter/material.dart';
import 'tokens.dart';

/// Typography carries the hierarchy this product depends on:
///
///   Spanish target  — serif, large, dominant. "This is the language."
///   Thai meaning    — Plex Sans Thai, secondary. Support, not the subject.
///   Grammar label   — Plex Sans, small, tertiary. Metadata.
///
/// The two-script pairing is the reason for the font choices. Plex Thai and
/// Plex Sans are one superfamily so the Thai and the UI Latin stay coherent;
/// the serif is deliberately *outside* that family so Spanish visibly reads as
/// a different thing on the page.
///
/// Thai line height is 1.7 throughout. Thai stacks an upper vowel and a tone
/// mark above the same consonant (ปั๊ป, ไม้โท + สระอิ), and at the 1.2–1.3
/// leading that looks fine for Latin those marks clip. This is the single most
/// common Thai typography defect and it is a quality-gate failure, not a nit.
abstract final class EdeType {
  static const _serif = 'SourceSerif';
  static const _thai = 'PlexThai';
  static const _sans = 'PlexSans';

  // Fallbacks so the app renders correctly before fonts are dropped in.
  static const _thaiFallback = ['Noto Sans Thai', 'Sarabun', 'sans-serif'];
  static const _latinFallback = ['Georgia', 'serif'];

  /// The Spanish sentence a lesson is teaching. Should dominate its card.
  static const spanishDisplay = TextStyle(
    fontFamily: _serif,
    fontFamilyFallback: _latinFallback,
    fontSize: 30,
    height: 1.28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const spanishBody = TextStyle(
    fontFamily: _serif,
    fontFamilyFallback: _latinFallback,
    fontSize: 21,
    height: 1.42,
  );

  static const spanishInline = TextStyle(
    fontFamily: _serif,
    fontFamilyFallback: _latinFallback,
    fontSize: 17,
    height: 1.45,
  );

  /// Thai explanation. Secondary to the Spanish above it.
  static const thaiBody = TextStyle(
    fontFamily: _thai,
    fontFamilyFallback: _thaiFallback,
    fontSize: 16,
    height: 1.70,
  );

  static const thaiBodySmall = TextStyle(
    fontFamily: _thai,
    fontFamilyFallback: _thaiFallback,
    fontSize: 14,
    height: 1.70,
  );

  static const thaiTitle = TextStyle(
    fontFamily: _thai,
    fontFamilyFallback: _thaiFallback,
    fontSize: 22,
    height: 1.55,
    fontWeight: FontWeight.w600,
  );

  static const thaiHeadline = TextStyle(
    fontFamily: _thai,
    fontFamilyFallback: _thaiFallback,
    fontSize: 27,
    height: 1.50,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  /// Grammar metadata: "sustantivo · masculino · singular". Tertiary.
  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.7,
  );

  static const button = TextStyle(
    fontFamily: _thai,
    fontFamilyFallback: _thaiFallback,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const numeric = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Learning-specific tokens that Material's ThemeData has no slot for.
@immutable
class EdeTokens extends ThemeExtension<EdeTokens> {
  const EdeTokens({
    required this.correct,
    required this.correctSurface,
    required this.retry,
    required this.retrySurface,
    required this.accent,
    required this.accentSurface,
    required this.hairline,
    required this.inkSoft,
    required this.inkFaint,
    required this.primarySurface,
  });

  final Color correct;
  final Color correctSurface;
  final Color retry;
  final Color retrySurface;
  final Color accent;
  final Color accentSurface;
  final Color hairline;
  final Color inkSoft;
  final Color inkFaint;
  final Color primarySurface;

  static const light = EdeTokens(
    correct: EdeColors.oliva,
    correctSurface: EdeColors.olivaSoft,
    retry: EdeColors.barro,
    retrySurface: EdeColors.barroSoft,
    accent: EdeColors.azafran,
    accentSurface: EdeColors.azafranSoft,
    hairline: EdeColors.hairline,
    inkSoft: EdeColors.inkSoft,
    inkFaint: EdeColors.inkFaint,
    primarySurface: EdeColors.cobaltSoft,
  );

  static const dark = EdeTokens(
    correct: Color(0xFF7FB183),
    correctSurface: Color(0xFF1B2A1E),
    retry: Color(0xFFD98E4A),
    retrySurface: Color(0xFF2A1F14),
    accent: Color(0xFFE8B24E),
    accentSurface: Color(0xFF2A2213),
    hairline: EdeColors.hairlineDark,
    inkSoft: EdeColors.inkSoftDark,
    inkFaint: Color(0xFF6E7A8A),
    primarySurface: Color(0xFF17263C),
  );

  @override
  EdeTokens copyWith() => this;

  @override
  EdeTokens lerp(ThemeExtension<EdeTokens>? other, double t) =>
      t < 0.5 ? this : (other as EdeTokens? ?? this);
}

extension EdeThemeX on BuildContext {
  EdeTokens get tokens => Theme.of(this).extension<EdeTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

abstract final class EdeTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;

    final scheme = ColorScheme(
      brightness: b,
      primary: isDark ? EdeColors.cobaltLight : EdeColors.cobalt,
      onPrimary: isDark ? EdeColors.paperDark : Colors.white,
      primaryContainer: isDark ? const Color(0xFF17263C) : EdeColors.cobaltSoft,
      onPrimaryContainer: isDark ? EdeColors.inkDark : EdeColors.cobaltDeep,
      secondary: isDark ? const Color(0xFFE8B24E) : EdeColors.azafran,
      onSecondary: EdeColors.ink,
      error: EdeColors.rose,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF2E1519) : EdeColors.roseSoft,
      onErrorContainer: isDark ? EdeColors.inkDark : EdeColors.rose,
      surface: isDark ? EdeColors.surfaceDark : EdeColors.surface,
      onSurface: isDark ? EdeColors.inkDark : EdeColors.ink,
      surfaceContainerLowest: isDark ? EdeColors.paperDark : EdeColors.paper,
      outlineVariant: isDark ? EdeColors.hairlineDark : EdeColors.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? EdeColors.paperDark : EdeColors.paper,
      splashFactory: InkSparkle.splashFactory,
      extensions: [isDark ? EdeTokens.dark : EdeTokens.light],
      textTheme: TextTheme(
        headlineLarge: EdeType.thaiHeadline.copyWith(color: scheme.onSurface),
        titleLarge: EdeType.thaiTitle.copyWith(color: scheme.onSurface),
        bodyLarge: EdeType.thaiBody.copyWith(color: scheme.onSurface),
        bodyMedium: EdeType.thaiBody
            .copyWith(color: isDark ? EdeColors.inkSoftDark : EdeColors.inkSoft),
        bodySmall: EdeType.thaiBodySmall
            .copyWith(color: isDark ? EdeColors.inkSoftDark : EdeColors.inkSoft),
        labelSmall: EdeType.label
            .copyWith(color: isDark ? const Color(0xFF6E7A8A) : EdeColors.inkFaint),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EdeRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? EdeColors.paperDark : EdeColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: EdeType.thaiTitle.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(EdeRadius.sheet)),
        ),
      ),
    );
  }
}

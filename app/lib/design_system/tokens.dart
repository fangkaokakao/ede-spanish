import 'package:flutter/material.dart';

/// Design tokens for EDE.
///
/// Direction: **azulejo** — the glazed cobalt-and-white tilework found across
/// Spain. Chosen deliberately over the obvious alternatives: flag red/yellow is
/// a cliché, and terracotta-on-cream is the current default look of generated
/// design, so it would read as templated rather than chosen. Azulejo gives a
/// palette that is authentically Spanish, calm enough for long study sessions,
/// and adult without being corporate.
///
/// Boldness is spent in exactly one place: the [AzulejoTile] motif used for
/// unit markers and the CEFR journey header. Everything else stays quiet.
///
/// Never scatter these values through widgets. Read them from the theme.
abstract final class EdeColors {
  // Core — cobalt, from tin-glazed ceramic
  static const cobalt = Color(0xFF1D4E9B);
  static const cobaltDeep = Color(0xFF12336A);
  static const cobaltSoft = Color(0xFFE7EEF9);
  static const cobaltLight = Color(0xFF7FA8E8); // dark-mode primary

  // Accent — azafrán. Used sparingly: the controlling noun in an agreement
  // diagram, an earned milestone. If it is on every screen it is wrong.
  static const azafran = Color(0xFFD99A21);
  static const azafranSoft = Color(0xFFFBF0DA);

  // Neutrals — cool paper, slight blue undertone so cobalt sits naturally
  static const paper = Color(0xFFF6F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF131A24);
  static const inkSoft = Color(0xFF4A5666);
  static const inkFaint = Color(0xFF8A94A3);
  static const hairline = Color(0xFFE2E6ED);

  // Dark
  static const paperDark = Color(0xFF0D1219);
  static const surfaceDark = Color(0xFF151C26);
  static const inkDark = Color(0xFFE8ECF2);
  static const inkSoftDark = Color(0xFFA3AEBD);
  static const hairlineDark = Color(0xFF27313E);

  // Semantic. `barro` is the *retry* colour, not an error colour: a wrong
  // answer in a lesson is a normal part of learning and must not read as a
  // system failure. True red is reserved for actual errors.
  static const oliva = Color(0xFF4A7C4E); // correct
  static const olivaSoft = Color(0xFFE8F1E8);
  static const barro = Color(0xFFB5651D); // try again
  static const barroSoft = Color(0xFFFBEDE0);
  static const rose = Color(0xFFA83A4B); // system error
  static const roseSoft = Color(0xFFFBE9EC);
}

abstract final class EdeSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Screen gutter. One value, everywhere.
  static const gutter = 20.0;
}

abstract final class EdeRadius {
  static const card = 18.0;
  static const control = 12.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

abstract final class EdeMotion {
  static const micro = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 250);
  static const sheet = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;
}

/// Minimum tap target. Enforced by components, not left to call sites.
const double kMinTap = 48.0;

/// A faithful Dart mirror of the SQL functions `assess.normalise_answer` and
/// `assess.check_answer`.
///
/// WHY THIS EXISTS, AND ITS LIMITS
///
/// The server is the only authority on correctness. In `DataSource.supabase`
/// mode the UI never calls this: it submits the answer and renders whatever
/// `assess.submit_attempt()` returns.
///
/// It exists solely so `DataSource.local` (development, offline demo, widget
/// tests) can behave like the server without a database. Because two
/// implementations of the same rule can drift apart, the port is deliberately
/// line-by-line rather than "equivalent", and `answer_matcher_test.dart`
/// asserts the exact cases the SQL suite asserts — including the punctuation
/// asymmetry bug that shipped in the SQL and was caught by test I5.
///
/// If you change the grading rule, change the SQL first and re-port.
abstract final class AnswerMatcher {
  /// Mirrors:
  ///   lower(btrim(regexp_replace(text, '\s+', ' ', 'g')))
  ///   then strip trailing [.!?¡¿]+
  ///   then optionally fold accents
  static String normalise(String? input, {required bool accentInsensitive}) {
    var s = (input ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    s = s.replaceAll(RegExp(r'[.!?¡¿]+$'), '');
    if (accentInsensitive) {
      const from = 'áéíóúüñ';
      const to = 'aeiouun';
      final b = StringBuffer();
      for (final ch in s.split('')) {
        final i = from.indexOf(ch);
        b.write(i >= 0 ? to[i] : ch);
      }
      s = b.toString();
    }
    return s;
  }

  /// Mirrors assess.check_answer. Normalisation is applied to BOTH sides —
  /// the server bug was applying it to only one.
  static bool matches(
    String? given, {
    List<String> accepted = const [],
    String? pattern,
    bool accentInsensitive = false,
  }) {
    final g = normalise(given, accentInsensitive: accentInsensitive);

    if (pattern != null) {
      return RegExp(pattern).hasMatch(g);
    }
    return accepted
        .map((a) => normalise(a, accentInsensitive: accentInsensitive))
        .contains(g);
  }
}

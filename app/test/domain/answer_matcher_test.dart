import 'package:ede/domain/answer_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// These cases mirror the SQL suite one-for-one. If the Dart mirror and the
/// server ever disagree, one of these fails — which is the whole point of
/// having the mirror be an explicit, tested port rather than "roughly the same".
void main() {
  group('normalise', () {
    test('trims, collapses whitespace and lowercases', () {
      expect(
        AnswerMatcher.normalise('  Me   LLAMO  Ana ', accentInsensitive: false),
        'me llamo ana',
      );
    });

    test('strips trailing sentence punctuation including Spanish marks', () {
      expect(AnswerMatcher.normalise('Me llamo Ana.', accentInsensitive: false),
          'me llamo ana');
      expect(
          AnswerMatcher.normalise('¿Cómo os llamáis?', accentInsensitive: false),
          '¿cómo os llamáis');
    });

    test('folds accents only when asked', () {
      expect(AnswerMatcher.normalise('llamáis', accentInsensitive: true), 'llamais');
      expect(AnswerMatcher.normalise('llamáis', accentInsensitive: false), 'llamáis');
      expect(AnswerMatcher.normalise('mañana', accentInsensitive: true), 'manana');
    });
  });

  group('the punctuation-asymmetry regression', () {
    // The server shipped a bug where normalisation was applied to the learner's
    // input but not to the accepted strings, so the CORRECT answer to the
    // vosotros exercise was graded wrong. Caught by SQL test I5.
    test('accepted answers are normalised too', () {
      expect(
        AnswerMatcher.matches('¿Cómo os llamáis?',
            accepted: const ['¿Cómo os llamáis?'], accentInsensitive: true),
        isTrue,
        reason: 'both sides must be normalised, not just the learner input',
      );
    });

    test('a missing accent is forgiven when accent_insensitive', () {
      expect(
        AnswerMatcher.matches('¿Como os llamais?',
            accepted: const ['¿Cómo os llamáis?'], accentInsensitive: true),
        isTrue,
      );
    });

    test('a wrong address form is still wrong', () {
      expect(
        AnswerMatcher.matches('¿Cómo se llaman ustedes?',
            accepted: const ['¿Cómo os llamáis?'], accentInsensitive: true),
        isFalse,
      );
    });
  });

  group('frame grading with a free name slot', () {
    // The seeded rule. The exercise asks for the learner's OWN name, so it must
    // accept any name while still requiring the grammatical frame.
    const pattern = r'^me llamo[ ]+[a-zà-ÿ].*$';

    bool check(String s) => AnswerMatcher.matches(s,
        pattern: pattern, accentInsensitive: true);

    test('accepts any real learner name', () {
      expect(check('Me llamo Ana'), isTrue);
      expect(check('Me llamo Somchai'), isTrue);
      expect(check('Me llamo Fangkao'), isTrue);
      expect(check('me llamo pedro.'), isTrue);
    });

    test('rejects a broken frame', () {
      expect(check('Llamo Ana'), isFalse, reason: 'missing me');
      expect(check('Me llamas Ana'), isFalse, reason: 'wrong person');
      expect(check('Yo Ana'), isFalse);
    });

    test('rejects a missing name', () {
      expect(check('Me llamo'), isFalse);
      expect(check('Me llamo   '), isFalse);
    });
  });
}

import 'package:ede/app/providers.dart';
import 'package:ede/data/local/app_database.dart';
import 'package:ede/data/repositories/local_repositories.dart';
import 'package:ede/data/repositories/speech_repository_impl.dart';
import 'package:ede/design_system/theme.dart';
import 'package:ede/domain/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harness: real repositories over an in-memory Drift database and the
/// embedded pack, with a fake recorder so no plugins are touched. Because the UI
/// only depends on the interfaces, these are the same widgets that ship.
class Harness {
  Harness()
      : db = AppDatabase.memory(),
        speech = FakeSpeechRepository();

  final AppDatabase db;
  final FakeSpeechRepository speech;

  late final CurriculumRepository curriculum = PackCurriculumRepository();
  late final AttemptRepository attempts = LocalAttemptRepository(db, curriculum);
  late final LearnerRepository learner =
      LocalLearnerRepository(db, curriculum, attempts, speech);
  late final GrammarRepository grammar =
      PackGrammarRepository(curriculum: curriculum);

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        curriculumRepositoryProvider.overrideWithValue(curriculum),
        attemptRepositoryProvider.overrideWithValue(attempts),
        learnerRepositoryProvider.overrideWithValue(learner),
        speechRepositoryProvider.overrideWithValue(speech),
        grammarRepositoryProvider.overrideWithValue(grammar),
      ];

  Future<void> dispose() => db.close();
}

/// Common phone widths, so overflow is caught in CI rather than on a device.
/// 320 is the narrowest iPhone SE logical width; 360 is the most common Android.
const kIphoneSe = Size(320, 568);
const kAndroidCommon = Size(360, 640);
const kIphone13 = Size(390, 844);

extension PumpX on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    required Harness harness,
    Size size = kIphone13,
    double textScale = 1.0,
  }) async {
    view.physicalSize = size * 3;
    view.devicePixelRatio = 3;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await pumpWidget(
      ProviderScope(
        overrides: harness.overrides,
        child: MaterialApp(
          theme: EdeTheme.light(),
          locale: const Locale('th'),
          supportedLocales: const [Locale('th'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: child,
          ),
        ),
      ),
    );
    await pumpAndSettle();
  }
}

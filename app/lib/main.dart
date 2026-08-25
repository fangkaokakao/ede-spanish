import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/env.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'data/local/app_database.dart';
import 'design_system/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surfaces the real exception + stack trace on the browser/device console
  // for any error that never reaches a widget's AsyncValue.when(error: ...)
  // builder. Chains to the previous handler rather than replacing it.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    log('EDE failed to start: ${details.exceptionAsString()}',
        name: 'ede.startup', level: 1000, error: details.exception, stackTrace: details.stack);
    previousOnError?.call(details);
  };
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    log('EDE failed to start: $error', name: 'ede.startup', level: 1000, error: error, stackTrace: stack);
    return previousPlatformOnError?.call(error, stack) ?? false;
  };

  // Supabase is initialised only when configured. With no --dart-define the app
  // runs entirely on the embedded pack, which is how the slice is evaluated
  // without a backend.
  if (Env.dataSource == DataSource.supabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  }

  final db = AppDatabase.file();

  runApp(ProviderScope(
    overrides: productionOverrides(db),
    child: const EdeApp(),
  ));
}

class EdeApp extends ConsumerWidget {
  const EdeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Español de España',
      debugShowCheckedModeBanner: false,
      theme: EdeTheme.light(),
      darkTheme: EdeTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Accessibility: support up to 200% text scale. The floor is clamped so
        // Thai diacritics never render below their legible size.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler:
                mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0),
          ),
          child: child!,
        );
      },
    );
  }
}

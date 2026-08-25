import 'dart:developer';

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

  // Surfaces the real exception + stack trace in the console for any error
  // that never reaches a widget's `error:` builder (e.g. one thrown outside
  // of a provider's rebuild), instead of only the Thai "failed to open"
  // fallback screen. Each hook chains to the previous/default handler rather
  // than replacing it.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    log('EDE failed to start: ${details.exceptionAsString()}',
        name: 'ede.startup', level: 1000, stackTrace: details.stack);
    previousOnError?.call(details);
  };
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    log('EDE failed to start: $error',
        name: 'ede.startup', level: 1000, stackTrace: stack);
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

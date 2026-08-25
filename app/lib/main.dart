import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/env.dart';
import 'app/router.dart';
import 'design_system/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Diagnostic only: without this, a startup exception that a widget's error
  // builder doesn't catch (e.g. thrown before runApp, or inside a Future
  // nothing awaits) has no console surface at all on web/release builds.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    developer.log(
      'EDE uncaught FlutterError during startup.',
      name: 'ede.startup',
      error: details.exception,
      stackTrace: details.stack,
      level: 1000, // SEVERE, so it is not filtered out of the console
    );
    previousOnError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'EDE uncaught platform/zone error during startup.',
      name: 'ede.startup',
      error: error,
      stackTrace: stack,
      level: 1000,
    );
    return false; // still forward to the default handler
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

  runApp(const ProviderScope(child: EdeApp()));
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

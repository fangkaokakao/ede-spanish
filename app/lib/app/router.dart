import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components.dart';
import '../design_system/theme.dart';
import '../design_system/tokens.dart';
import '../features/grammar/why_sheet.dart';
import '../features/home/home_screen.dart';
import '../features/learn/course_map_screen.dart';
import '../features/learn/unit_screen.dart';
import '../features/lesson/lesson_complete_screen.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import 'providers.dart';

/// Five tabs, not six. `Exam` is deliberately not a permanent destination:
/// most learners are not exam-driven, and an always-visible DELE tab makes the
/// product feel like a cram school.
///
/// The lesson player, its completion screen and onboarding sit OUTSIDE the shell
/// so the tab bar is hidden during focused flows.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Decides between onboarding and Home once, on cold start.
      GoRoute(path: '/', builder: (_, __) => const _Gate()),

      GoRoute(path: '/onboarding', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/goal', builder: (_, __) => const GoalScreen()),
      GoRoute(
          path: '/onboarding/experience', builder: (_, __) => const ExperienceScreen()),
      GoRoute(
          path: '/onboarding/daily-goal', builder: (_, __) => const DailyGoalScreen()),
      GoRoute(
          path: '/onboarding/self-reference',
          builder: (_, __) => const SelfReferenceScreen()),

      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:id/complete',
        builder: (context, state) => LessonCompleteScreen(
          lessonId: state.pathParameters['id']!,
          awarded: state.uri.queryParameters['awarded'] != 'false',
        ),
      ),
      GoRoute(
        path: '/unit/:id',
        builder: (context, state) => UnitScreen(unitId: state.pathParameters['id']!),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/learn', builder: (_, __) => const CourseMapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/practice', builder: (_, __) => const _NotYet('ฝึกฝน')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tutor', builder: (_, __) => const _TutorNotConnected()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/progress', builder: (_, __) => const _NotYet('ความก้าวหน้า')),
          ]),
        ],
      ),
    ],
  );
});

/// Routes to onboarding or Home. Reads preferences once rather than guarding
/// every route with a redirect, which would re-read on every navigation.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return prefs.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      error: (e, st) {
        // Diagnostic only: this is the app's cold-start gate, so a thrown
        // error here has no other console surface — Riverpod hands it to
        // this builder instead of letting it reach FlutterError/zone
        // handlers. Logged unconditionally (not just in debug builds) so a
        // deployed/release build's browser console still shows the real
        // cause instead of only the Thai fallback message.
        developer.log(
          'EDE failed to start: preferencesProvider entered an error state.',
          name: 'ede.startup',
          error: e,
          stackTrace: st,
          level: 1000, // SEVERE, so it is not filtered out of the console
        );
        return Scaffold(
          body: EdeErrorState(
            message: 'เปิดแอปไม่สำเร็จ กรุณาลองอีกครั้ง',
            onRetry: () => ref.invalidate(preferencesProvider),
          ),
        );
      },
      data: (p) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(p.onboardingComplete ? '/home' : '/onboarding');
        });
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        height: 68,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: context.tokens.primarySurface,
        labelTextStyle:
            WidgetStatePropertyAll(EdeType.thaiBodySmall.copyWith(fontSize: 11.5)),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'หน้าแรก'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'เรียน'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'ฝึกฝน'),
          NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'ครู AI'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'ความก้าวหน้า'),
        ],
      ),
    );
  }
}

/// Out of scope for this slice, and says so plainly rather than showing a
/// half-built screen.
class _NotYet extends StatelessWidget {
  const _NotYet(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EdeEmptyState(
          title: 'ยังไม่เปิดใช้ในเวอร์ชันนี้',
          body: 'เวอร์ชันนี้เน้นพิสูจน์วงจรการเรียนหนึ่งบทให้ครบก่อน '
              'ส่วน “$title” จะมาในเฟสถัดไป',
        ),
      );
}

class _TutorNotConnected extends StatelessWidget {
  const _TutorNotConnected();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ครู AI')),
        body: Padding(
          padding: const EdgeInsets.all(EdeSpace.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EdeEmptyState(
                title: 'ครู AI ยังไม่ได้เชื่อมต่อ',
                body: 'แอปจะไม่แสดงคำตอบที่แต่งขึ้นเองว่าเป็นคำตอบของครู AI '
                    'ระหว่างนี้คำอธิบายทั้งหมดในบทเรียนเขียนโดยผู้เชี่ยวชาญ '
                    'และกดดูได้จากปุ่ม “ทำไม?”',
              ),
              const SizedBox(height: EdeSpace.lg),
              EdeTextButton(
                icon: Icons.help_outline_rounded,
                label: 'ลองดูตัวอย่างคำอธิบาย',
                onPressed: () => showWhySheet(
                  context,
                  blockId: 'b1',
                  conceptId: '11111111-1111-4111-8111-111111111101',
                ),
              ),
            ],
          ),
        ),
      );
}

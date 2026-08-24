import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/env.dart';
import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// Home answers one question before anything else: **เรียนอะไรต่อ**.
///
/// The top of the screen is a single decision with a single button. Analytics
/// belong in Progress; a learner opening the app on a train has one job, and a
/// wall of numbers is how they end up doing nothing. The only figure here is the
/// streak chip, and it is deliberately small.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(dailyPlanProvider);
    final stats = ref.watch(statsProvider);
    final progress = ref.watch(progressProvider);
    final units = ref.watch(unitsProvider(Cefr.preA1));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyPlanProvider);
            ref.invalidate(statsProvider);
            ref.invalidate(progressProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: EdeSpace.xxxl),
            children: [
              if (Env.isLocalMode) const LocalModeBanner(),
              _Header(stats: stats),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: EdeSpace.gutter),
                child: plan.when(
                  loading: () => const _LoadingHome(),
                  error: (e, _) => EdeErrorState(
                    message: 'โหลดแผนการเรียนวันนี้ไม่ได้',
                    onRetry: () => ref.invalidate(dailyPlanProvider),
                  ),
                  data: (p) => p.items.isEmpty
                      ? EdeEmptyState(
                          title: 'วันนี้ยังไม่มีอะไรค้าง',
                          body: 'เปิดคอร์สเพื่อเลือกบทเรียนที่อยากเรียนได้เลย',
                          actionLabel: 'ดูคอร์ส',
                          onAction: () => context.go('/learn'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ContinueCard(plan: p),
                            const SizedBox(height: EdeSpace.xl),
                            _PlanList(plan: p),
                            const SizedBox(height: EdeSpace.xl),
                            _UnitProgress(units: units, progress: progress),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingHome extends StatelessWidget {
  const _LoadingHome();
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EdeSkeleton(height: 210),
          SizedBox(height: EdeSpace.xl),
          EdeSkeleton(height: 130),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.stats});
  final AsyncValue<LearnerStats> stats;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'สวัสดีตอนเช้า'
        : hour < 18
            ? 'สวัสดีตอนบ่าย'
            : 'สวัสดีตอนเย็น';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          EdeSpace.gutter, EdeSpace.lg, EdeSpace.gutter, EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(greeting,
                    style: EdeType.thaiHeadline
                        .copyWith(color: context.colors.onSurface)),
              ),
              stats.maybeWhen(
                data: (s) => s.currentStreak == 0
                    ? const SizedBox.shrink()
                    : _StreakChip(days: s.currentStreak),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: EdeSpace.xs),
          Text('Pre-A1 · ทักทายและแนะนำตัว',
              style:
                  EdeType.thaiBodySmall.copyWith(color: context.tokens.inkFaint)),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: context.tokens.accentSurface,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 15, color: context.tokens.accent),
          const SizedBox(width: 4),
          Text('$days วัน',
              style: EdeType.numeric.copyWith(color: context.tokens.accent)),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.plan});
  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    final item = plan.current ?? plan.items.first;

    return EdeCard(
      padding: const EdgeInsets.all(EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AzulejoTile(size: 52, progress: 0.5, highlight: true),
              const SizedBox(width: EdeSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GrammarLabel(parts: ['เรียนอะไรต่อ']),
                    const SizedBox(height: 6),
                    Text(item.labelTh,
                        style: EdeType.thaiTitle
                            .copyWith(color: context.colors.onSurface)),
                    const SizedBox(height: 2),
                    Text('ประมาณ ${item.minutes} นาที',
                        style: EdeType.thaiBodySmall
                            .copyWith(color: context.tokens.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EdeSpace.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdeSpace.lg),
            decoration: BoxDecoration(
              color: context.tokens.primarySurface,
              borderRadius: BorderRadius.circular(EdeRadius.control),
            ),
            child: const SpanishLine(
              es: 'Me llamo…',
              th: 'ฉันชื่อ…',
              style: EdeType.spanishBody,
            ),
          ),
          const SizedBox(height: EdeSpace.lg),
          EdePrimaryButton(
            label: 'เรียนต่อ',
            icon: Icons.play_arrow_rounded,
            onPressed: item.lessonId == null
                ? () => context.go('/learn')
                : () => context.push('/lesson/${item.lessonId}'),
          ),
        ],
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({required this.plan});
  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: EdeSpace.xs, bottom: EdeSpace.md),
          child: Text('วันนี้ · ประมาณ ${plan.budgetMinutes} นาที',
              style: EdeType.thaiBodySmall
                  .copyWith(color: context.tokens.inkFaint)),
        ),
        EdeCard(
          padding: const EdgeInsets.symmetric(vertical: EdeSpace.xs),
          child: Column(
            children: [
              for (var i = 0; i < plan.items.length; i++) ...[
                _PlanRow(item: plan.items[i]),
                if (i != plan.items.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(color: context.colors.outlineVariant),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item});
  final PlanItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (icon, colour) = switch (item.kind) {
      'review' => (Icons.refresh_rounded, context.colors.primary),
      'lesson' => (Icons.menu_book_rounded, context.colors.primary),
      'speaking' => (Icons.mic_none_rounded, t.accent),
      'remediation' => (Icons.build_outlined, t.retry),
      _ => (Icons.headphones_rounded, context.colors.primary),
    };

    return Semantics(
      label: '${item.labelTh}, ${item.minutes} นาที, '
          '${item.done ? "เสร็จแล้ว" : "ยังไม่เสร็จ"}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: EdeSpace.lg, vertical: EdeSpace.md),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: item.done
                  ? Icon(Icons.check_circle_rounded, size: 22, color: t.correct)
                  : Icon(icon, size: 22, color: colour),
            ),
            const SizedBox(width: EdeSpace.md),
            Expanded(
              child: Text(
                item.count != null
                    ? '${item.labelTh} (${item.count} คำ)'
                    : item.labelTh,
                style: EdeType.thaiBody.copyWith(
                  color: item.done ? t.inkFaint : context.colors.onSurface,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                  decorationColor: t.inkFaint,
                ),
              ),
            ),
            Text('${item.minutes} นาที',
                style: EdeType.numeric.copyWith(color: t.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _UnitProgress extends StatelessWidget {
  const _UnitProgress({required this.units, required this.progress});

  final AsyncValue<List<UnitSummary>> units;
  final AsyncValue<Map<String, LessonProgress>> progress;

  @override
  Widget build(BuildContext context) {
    return units.maybeWhen(
      data: (us) {
        if (us.isEmpty) return const SizedBox.shrink();
        final u = us.first;
        final prog = progress.valueOrNull ?? const <String, LessonProgress>{};
        final done = u.lessons
            .where((l) => prog[l.id]?.state == LessonState.completed)
            .length;
        final current = u.lessons
            .indexWhere((l) => prog[l.id]?.state != LessonState.completed);

        return EdeCard(
          onTap: () => context.push('/unit/${u.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(u.titleTh,
                        style: EdeType.thaiBody
                            .copyWith(color: context.colors.onSurface)),
                  ),
                  Text('$done/${u.lessons.length}',
                      style: EdeType.numeric
                          .copyWith(color: context.tokens.inkFaint)),
                ],
              ),
              const SizedBox(height: EdeSpace.md),
              AzulejoProgressRow(
                total: u.lessons.length,
                completed: done,
                currentIndex: current < 0 ? u.lessons.length : current,
              ),
            ],
          ),
        );
      },
      orElse: () => const EdeSkeleton(height: 88),
    );
  }
}

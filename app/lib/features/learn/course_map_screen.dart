import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/local/content_pack.dart' show kAvailableLessonSlugs;
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// The CEFR journey plus the units of the current level.
///
/// Levels with no QA-complete curriculum are shown but not enterable and are
/// labelled "เร็วๆ นี้" — never stubbed with placeholder lessons, because
/// calling incomplete content A2 is how a course lies to a learner.
class CourseMapScreen extends ConsumerWidget {
  const CourseMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelsProvider);
    final units = ref.watch(unitsProvider(Cefr.preA1));
    final progress = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('เรียน')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unitsProvider(Cefr.preA1));
          ref.invalidate(progressProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              EdeSpace.gutter, EdeSpace.sm, EdeSpace.gutter, EdeSpace.xxxl),
          children: [
            levels.when(
              loading: () => const EdeSkeleton(height: 78),
              error: (e, _) => EdeErrorState(
                message: 'โหลดระดับไม่ได้',
                onRetry: () => ref.invalidate(levelsProvider),
              ),
              data: (ls) => _CefrJourney(levels: ls),
            ),
            const SizedBox(height: EdeSpace.xl),
            units.when(
              loading: () => const Column(
                children: [
                  EdeSkeleton(height: 150),
                  SizedBox(height: EdeSpace.lg),
                  EdeSkeleton(height: 150),
                ],
              ),
              error: (e, _) => EdeErrorState(
                message: 'โหลดหน่วยการเรียนไม่ได้ กรุณาลองอีกครั้ง',
                onRetry: () => ref.invalidate(unitsProvider(Cefr.preA1)),
              ),
              data: (us) => us.isEmpty
                  ? const EdeEmptyState(
                      title: 'ยังไม่มีหน่วยการเรียน',
                      body: 'เนื้อหาระดับนี้ยังไม่ได้เผยแพร่')
                  : Column(
                      children: [
                        for (var i = 0; i < us.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: EdeSpace.lg),
                            child: _UnitCard(
                              unit: us[i],
                              // `us` is already sorted by UnitSummary.sortOrder
                              // (see PackCurriculumRepository.unitsForLevel), so
                              // this position is the real course order — never
                              // hardcode "หน่วยที่ 1" for every card.
                              position: i + 1,
                              progress: progress.valueOrNull ?? const {},
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CefrJourney extends StatelessWidget {
  const _CefrJourney({required this.levels});
  final List<CefrLevel> levels;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final l in levels)
            Padding(
              padding: const EdgeInsets.only(right: EdeSpace.sm),
              child: Container(
                width: 96,
                padding: const EdgeInsets.all(EdeSpace.md),
                decoration: BoxDecoration(
                  color: l.isAvailable
                      ? context.tokens.primarySurface
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                  border: Border.all(
                    color: l.isAvailable
                        ? context.colors.primary.withValues(alpha: .5)
                        : context.colors.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.level.label,
                        style: EdeType.thaiBody.copyWith(
                          color: l.isAvailable
                              ? context.colors.primary
                              : context.tokens.inkFaint,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(l.isAvailable ? l.taglineTh : 'เร็วๆ นี้',
                        maxLines: 2,
                        style: EdeType.thaiBodySmall.copyWith(
                            fontSize: 11.5, color: context.tokens.inkFaint)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitCard extends ConsumerWidget {
  const _UnitCard({required this.unit, required this.position, required this.progress});

  final UnitSummary unit;
  final int position;
  final Map<String, LessonProgress> progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = unit.lessons
        .where((l) => progress[l.id]?.state == LessonState.completed)
        .length;
    final currentIndex = unit.lessons.indexWhere(
        (l) => progress[l.id]?.state != LessonState.completed);
    final isFoundation = unit.sections.isNotEmpty;

    return EdeCard(
      padding: const EdgeInsets.all(EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrammarLabel(parts: [
            unit.level.label,
            isFoundation ? 'ปูพื้นฐาน' : 'หน่วยที่ $position',
          ]),
          const SizedBox(height: 6),
          Text(unit.titleTh,
              style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
          if (unit.titleEs != null)
            Text(unit.titleEs!,
                style: EdeType.spanishInline
                    .copyWith(color: context.tokens.inkFaint)),
          const SizedBox(height: EdeSpace.md),
          Text(unit.subtitleTh,
              style:
                  EdeType.thaiBodySmall.copyWith(color: context.tokens.inkSoft)),
          const SizedBox(height: EdeSpace.lg),
          AzulejoProgressRow(
            total: unit.lessons.length,
            completed: completed,
            currentIndex: currentIndex < 0 ? unit.lessons.length : currentIndex,
          ),
          const SizedBox(height: EdeSpace.lg),
          if (isFoundation) ...[
            const FoundationSoundIntroBanner(),
            const SizedBox(height: EdeSpace.lg),
            const ThaiHelperToggle(),
            const SizedBox(height: EdeSpace.lg),
            for (final s in unit.sections)
              Padding(
                padding: const EdgeInsets.only(bottom: EdeSpace.md),
                child: _SectionGroup(section: s, progress: progress),
              ),
          ] else ...[
            Divider(color: context.colors.outlineVariant),
            for (final l in unit.lessons)
              _LessonRow(
                lesson: l,
                state: progress[l.id]?.state ?? LessonState.notStarted,
                // Only lessons the pack actually contains are enterable.
                enterable: kAvailableLessonSlugs.contains(l.slug),
              ),
          ],
        ],
      ),
    );
  }
}

/// One major Foundation 0 section card: number/bonus badge, title, short Thai
/// description, and either its lesson(s) (current/completed/locked, exactly
/// like a normal unit) or a plain "เร็วๆ นี้" note when nothing is authored
/// for it yet — never a stubbed, unenterable lesson row.
class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.section, required this.progress});

  final CourseSection section;
  final Map<String, LessonProgress> progress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isBonus = section.sortOrder >= 100;
    final hasLessons = section.lessons.isNotEmpty;
    final completed = section.lessons
        .where((l) => progress[l.id]?.state == LessonState.completed)
        .length;
    final allDone = hasLessons && completed == section.lessons.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdeSpace.lg),
      decoration: BoxDecoration(
        color: hasLessons ? context.colors.surface : context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionBadge(bonus: isBonus, done: allDone, active: hasLessons),
              const SizedBox(width: EdeSpace.md),
              // A vertical stack (rather than a trailing Row item) so the
              // minutes/"เร็วๆ นี้" marker wraps under the title instead of
              // forcing a fixed-width sibling to fight the title for space —
              // at 200% text scale that fight is what overflowed the Row.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.titleTh,
                        style: EdeType.thaiBody.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 2),
                    Text(section.descriptionTh,
                        style: EdeType.thaiBodySmall
                            .copyWith(color: t.inkSoft)),
                    const SizedBox(height: 4),
                    Text(
                      hasLessons ? '${section.totalMinutes} นาที' : 'เร็วๆ นี้',
                      style: EdeType.numeric.copyWith(color: t.inkFaint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasLessons) ...[
            const SizedBox(height: EdeSpace.sm),
            Divider(color: context.colors.outlineVariant),
            for (final l in section.lessons)
              _LessonRow(
                lesson: l,
                state: progress[l.id]?.state ?? LessonState.notStarted,
                enterable: kAvailableLessonSlugs.contains(l.slug),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge(
      {required this.bonus, required this.done, required this.active});
  final bool bonus, done, active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (done) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: t.correctSurface,
        child: Icon(Icons.check_rounded, size: 18, color: t.correct),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: active ? t.primarySurface : context.colors.outlineVariant,
      child: Icon(
        bonus ? Icons.card_giftcard_rounded : Icons.circle_outlined,
        size: 16,
        color: active ? context.colors.primary : t.inkFaint,
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.state,
    required this.enterable,
  });

  final LessonSummary lesson;
  final LessonState state;
  final bool enterable;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = state == LessonState.completed;

    final (icon, colour) = done
        ? (Icons.check_circle_rounded, t.correct)
        : enterable
            ? (Icons.play_circle_fill_rounded, context.colors.primary)
            : (Icons.lock_outline_rounded, t.inkFaint);

    return Semantics(
      button: enterable,
      label: '${lesson.titleTh}, ${lesson.estimatedMinutes} นาที, '
          '${done ? "เรียนจบแล้ว" : enterable ? "พร้อมเรียน" : "ยังไม่เปิด"}',
      child: InkWell(
        onTap: enterable ? () => context.push('/lesson/${lesson.id}') : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTap + 4),
          padding: const EdgeInsets.symmetric(vertical: EdeSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: colour),
              const SizedBox(width: EdeSpace.md),
              // The minutes/"เร็วๆ นี้" marker sits under the title, not as a
              // fixed-width trailing Row item, so it never has to fight the
              // title for horizontal space at large text scales.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.titleTh,
                        style: EdeType.thaiBody.copyWith(
                          color: enterable || done
                              ? context.colors.onSurface
                              : t.inkFaint,
                        )),
                    const SizedBox(height: 2),
                    Text(
                        enterable || done
                            ? '${lesson.estimatedMinutes} นาที'
                            : 'เร็วๆ นี้',
                        style: EdeType.numeric.copyWith(color: t.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

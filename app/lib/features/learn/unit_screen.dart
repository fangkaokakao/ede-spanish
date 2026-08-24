import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// A single unit, opened from the course map. Same data, more room: the unit's
/// real-world promise is the headline, because that is what makes a learner
/// want to start.
class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key, required this.unitId});
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitProvider(unitId));
    final progress = ref.watch(progressProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('หน่วยการเรียน')),
      body: unitAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(EdeSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EdeSkeleton(height: 26, width: 200),
              SizedBox(height: EdeSpace.lg),
              EdeSkeleton(height: 60),
              SizedBox(height: EdeSpace.lg),
              EdeSkeleton(height: 200),
            ],
          ),
        ),
        error: (e, _) => EdeErrorState(
          message: 'โหลดหน่วยการเรียนไม่ได้',
          onRetry: () => ref.invalidate(unitProvider(unitId)),
        ),
        data: (unit) {
          final completed = unit.lessons
              .where((l) => progress[l.id]?.state == LessonState.completed)
              .length;
          final currentIndex = unit.lessons.indexWhere(
              (l) => progress[l.id]?.state != LessonState.completed);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                EdeSpace.gutter, EdeSpace.sm, EdeSpace.gutter, EdeSpace.xxxl),
            children: [
              GrammarLabel(parts: [unit.level.label]),
              const SizedBox(height: 6),
              Text(unit.titleTh,
                  style: EdeType.thaiHeadline
                      .copyWith(color: context.colors.onSurface)),
              if (unit.titleEs != null)
                Text(unit.titleEs!,
                    style: EdeType.spanishBody
                        .copyWith(color: context.tokens.inkFaint)),
              const SizedBox(height: EdeSpace.lg),
              Container(
                padding: const EdgeInsets.all(EdeSpace.lg),
                decoration: BoxDecoration(
                  color: context.tokens.primarySurface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                ),
                child: Text(unit.subtitleTh,
                    style: EdeType.thaiBody
                        .copyWith(color: context.colors.onSurface)),
              ),
              const SizedBox(height: EdeSpace.xl),
              AzulejoProgressRow(
                total: unit.lessons.length,
                completed: completed,
                currentIndex:
                    currentIndex < 0 ? unit.lessons.length : currentIndex,
              ),
              const SizedBox(height: EdeSpace.xl),
              for (final l in unit.lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: EdeSpace.sm),
                  child: EdeCard(
                    onTap: l.slug == 'pre-a1-u1-l3'
                        ? () => context.push('/lesson/${l.id}')
                        : null,
                    child: Row(
                      children: [
                        AzulejoTile(
                          size: 34,
                          progress: progress[l.id]?.state == LessonState.completed
                              ? 1
                              : 0,
                          locked: l.slug != 'pre-a1-u1-l3',
                        ),
                        const SizedBox(width: EdeSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.titleTh,
                                  style: EdeType.thaiBody
                                      .copyWith(color: context.colors.onSurface)),
                              Text(
                                  l.slug == 'pre-a1-u1-l3'
                                      ? '${l.estimatedMinutes} นาที'
                                      : 'เร็วๆ นี้',
                                  style: EdeType.thaiBodySmall
                                      .copyWith(color: context.tokens.inkFaint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

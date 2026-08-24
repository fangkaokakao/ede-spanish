import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';

/// Success state. Frames the win as a new *ability*, not as points — and names
/// the next lesson, so momentum has somewhere to go.
///
/// A replayed completion says so honestly instead of pretending to award again.
class LessonCompleteScreen extends ConsumerWidget {
  const LessonCompleteScreen({
    super.key,
    required this.lessonId,
    this.awarded = true,
  });

  final String lessonId;
  final bool awarded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final plan = ref.watch(dailyPlanProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding
          (
          padding: const EdgeInsets.all(EdeSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const AzulejoTile(size: 84, progress: 1, highlight: true),
              const SizedBox(height: EdeSpace.xl),
              Text(awarded ? 'เรียนจบบทนี้แล้ว' : 'บทนี้เรียนจบไปก่อนหน้านี้แล้ว',
                  style: EdeType.thaiHeadline
                      .copyWith(color: context.colors.onSurface)),
              const SizedBox(height: EdeSpace.md),

              // Ability, not XP.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EdeSpace.lg),
                decoration: BoxDecoration(
                  color: context.tokens.correctSurface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ตอนนี้คุณทำได้แล้ว',
                        style: EdeType.thaiBodySmall
                            .copyWith(color: context.tokens.correct)),
                    const SizedBox(height: EdeSpace.xs),
                    Text('บอกชื่อตัวเอง และถามชื่อคนอื่นได้ทั้งแบบกันเองและแบบสุภาพ',
                        style: EdeType.thaiBody
                            .copyWith(color: context.colors.onSurface)),
                    const SizedBox(height: EdeSpace.md),
                    Text('Me llamo…   ¿Cómo os llamáis?',
                        style: EdeType.spanishInline
                            .copyWith(color: context.tokens.correct)),
                  ],
                ),
              ),

              const SizedBox(height: EdeSpace.lg),
              stats.when(
                loading: () => const EdeSkeleton(height: 14, width: 160),
                error: (_, __) => const SizedBox.shrink(),
                data: (s) => Row(
                  children: [
                    _Stat(label: 'บทเรียน', value: '${s.lessonsCompleted}'),
                    const SizedBox(width: EdeSpace.xl),
                    _Stat(label: 'เวลาเรียน', value: '${s.totalMinutes} นาที'),
                    const SizedBox(width: EdeSpace.xl),
                    _Stat(label: 'ต่อเนื่อง', value: '${s.currentStreak} วัน'),
                  ],
                ),
              ),

              const SizedBox(height: EdeSpace.xl),
              plan.when(
                loading: () => const EdeSkeleton(height: 60),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) {
                  final next = p.current;
                  if (next == null) {
                    return Text('วันนี้ทำครบตามเป้าแล้ว',
                        style: EdeType.thaiBody
                            .copyWith(color: context.tokens.inkSoft));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GrammarLabel(parts: ['ต่อไป']),
                      const SizedBox(height: EdeSpace.xs),
                      Text('${next.labelTh} · ${next.minutes} นาที',
                          style: EdeType.thaiBody
                              .copyWith(color: context.colors.onSurface)),
                    ],
                  );
                },
              ),

              const Spacer(),
              EdePrimaryButton(
                label: 'กลับหน้าแรก',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: EdeSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
          Text(label,
              style: EdeType.thaiBodySmall
                  .copyWith(color: context.tokens.inkFaint)),
        ],
      );
}

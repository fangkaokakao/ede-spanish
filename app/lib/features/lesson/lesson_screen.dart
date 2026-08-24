import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';
import 'block_renderer.dart';

/// The lesson player.
///
/// One scroll, blocks in authored order, driven entirely by the schema. The
/// bottom nav is hidden here: a lesson is a focused flow, and the close button
/// is the only way out (it saves position first).
///
/// The rhythm the curriculum enforces — teach a little, practise, explain,
/// practise — is a property of the authored block order, not of this file.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _scroll = ScrollController();
  int _furthestBlock = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _noteBlockViewed(int index) {
    if (index <= _furthestBlock) return;
    _furthestBlock = index;
    // Reading position is one of the few things a client legitimately owns.
    ref.read(learnerRepositoryProvider).markBlockViewed(widget.lessonId, index);
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
    final sessionAsync = ref.watch(lessonSessionProvider(widget.lessonId));

    return Scaffold(
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const _LoadingLesson(),
          error: (e, _) => EdeErrorState(
            message: 'โหลดบทเรียนไม่ได้ กรุณาลองอีกครั้ง',
            onRetry: () => ref.invalidate(lessonProvider(widget.lessonId)),
          ),
          data: (lesson) {
            if (lesson.blocks.isEmpty) {
              return const EdeEmptyState(
                title: 'บทเรียนนี้ยังไม่มีเนื้อหา',
                body: 'เนื้อหายังไม่ได้เผยแพร่ ลองเลือกบทเรียนอื่นก่อน',
              );
            }
            return sessionAsync.when(
              loading: () => const _LoadingLesson(),
              error: (e, _) => EdeErrorState(
                message: 'เริ่มบทเรียนไม่ได้ ตรวจการเชื่อมต่อแล้วลองอีกครั้ง',
                onRetry: () =>
                    ref.invalidate(lessonSessionProvider(widget.lessonId)),
              ),
              data: (sessionId) => _Body(
                lesson: lesson,
                sessionId: sessionId,
                scroll: _scroll,
                onBlockViewed: _noteBlockViewed,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingLesson extends StatelessWidget {
  const _LoadingLesson();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(EdeSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EdeSkeleton(height: 12, width: 90),
            SizedBox(height: EdeSpace.lg),
            EdeSkeleton(height: 26, width: 200),
            SizedBox(height: EdeSpace.xl),
            EdeSkeleton(height: 120),
            SizedBox(height: EdeSpace.lg),
            EdeSkeleton(height: 160),
          ],
        ),
      );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.lesson,
    required this.sessionId,
    required this.scroll,
    required this.onBlockViewed,
  });

  final Lesson lesson;
  final String sessionId;
  final ScrollController scroll;
  final void Function(int) onBlockViewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satisfied = ref.watch(satisfiedProvider);

    return Column(
      children: [
        _LessonHeader(lesson: lesson),
        Expanded(
          child: ListView.separated(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
                EdeSpace.gutter, EdeSpace.lg, EdeSpace.gutter, EdeSpace.xxxl),
            itemCount: lesson.blocks.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: EdeSpace.lg),
            itemBuilder: (context, i) {
              if (i == lesson.blocks.length) {
                return _FinishSection(lesson: lesson, satisfied: satisfied);
              }
              // Notify after layout so the write happens off the build path.
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => onBlockViewed(i));
              return BlockRenderer(
                block: lesson.blocks[i],
                lessonId: lesson.id,
                sessionId: sessionId,
                onExerciseGraded: (_, __) => ref.invalidate(satisfiedProvider),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          EdeSpace.gutter, EdeSpace.sm, EdeSpace.sm, EdeSpace.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
            bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GrammarLabel(parts: ['Pre-A1', 'หน่วยที่ 1']),
                    const SizedBox(height: 4),
                    Text(lesson.titleTh,
                        style: EdeType.thaiTitle
                            .copyWith(color: context.colors.onSurface)),
                    if (lesson.titleEs != null)
                      Text(lesson.titleEs!,
                          style: EdeType.spanishInline
                              .copyWith(color: context.tokens.inkFaint)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'ปิดบทเรียน',
                iconSize: 24,
                constraints:
                    const BoxConstraints(minWidth: kMinTap, minHeight: kMinTap),
              ),
            ],
          ),
          const SizedBox(height: EdeSpace.md),
          // The goal, in the learner's language, before any content.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_outlined, size: 16, color: context.colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lesson.goalTh,
                    style: EdeType.thaiBodySmall
                        .copyWith(color: context.colors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Completion is server-verified. This section shows exactly what is still
/// owed, so the primary button is never a mystery.
class _FinishSection extends ConsumerStatefulWidget {
  const _FinishSection({required this.lesson, required this.satisfied});

  final Lesson lesson;
  final AsyncValue<({Set<String> correct, Set<String> spoken})> satisfied;

  @override
  ConsumerState<_FinishSection> createState() => _FinishSectionState();
}

class _FinishSectionState extends ConsumerState<_FinishSection> {
  bool _busy = false;
  String? _error;
  List<String> _missing = const [];

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(learnerRepositoryProvider)
          .completeLesson(widget.lesson.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _missing = res.missing;
      });

      if (res.completed) {
        ref.invalidate(progressProvider);
        ref.invalidate(statsProvider);
        ref.invalidate(dailyPlanProvider);
        if (mounted) {
          context.go('/lesson/${widget.lesson.id}/complete'
              '?awarded=${res.awarded}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'ยังจบบทเรียนไม่ได้ ลองอีกครั้ง — ความคืบหน้าของคุณยังอยู่';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = widget.lesson.completionRules;
    final sat = widget.satisfied.valueOrNull;
    final correct = sat?.correct ?? const <String>{};
    final spoken = sat?.spoken ?? const <String>{};

    final done = rules.requiredCorrectExercises.every(correct.contains) &&
        rules.requiredSpeechExercises.every(spoken.contains);

    return EdeCard(
      padding: const EdgeInsets.all(EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('จบบทเรียน',
              style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
          const SizedBox(height: EdeSpace.sm),
          Text(
            done
                ? 'ทำครบแล้ว กดเพื่อบันทึกความคืบหน้า'
                : 'ทำสิ่งเหล่านี้ให้ครบก่อน แล้วบทเรียนจะถูกบันทึกว่าเรียนจบ',
            style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkSoft),
          ),
          const SizedBox(height: EdeSpace.lg),
          Wrap(
            spacing: EdeSpace.sm,
            runSpacing: EdeSpace.sm,
            children: [
              for (var i = 0; i < rules.requiredCorrectExercises.length; i++)
                RequirementChip(
                  labelTh: 'แบบฝึกหัดที่ ${i + 1}',
                  done: correct.contains(rules.requiredCorrectExercises[i]),
                ),
              for (final id in rules.requiredSpeechExercises)
                RequirementChip(labelTh: 'ฝึกพูด', done: spoken.contains(id)),
            ],
          ),
          if (_missing.isNotEmpty) ...[
            const SizedBox(height: EdeSpace.md),
            Text('ยังเหลืออีก ${_missing.length} อย่าง',
                style: EdeType.thaiBodySmall
                    .copyWith(color: context.tokens.retry)),
          ],
          if (_error != null) ...[
            const SizedBox(height: EdeSpace.md),
            Text(_error!,
                style:
                    EdeType.thaiBodySmall.copyWith(color: context.tokens.retry)),
          ],
          const SizedBox(height: EdeSpace.lg),
          EdePrimaryButton(
            label: 'จบบทเรียนนี้',
            icon: Icons.check_rounded,
            loading: _busy,
            onPressed: done ? _finish : null,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// The ทำไม? sheet — the most important interaction in the product.
///
/// Resolution order (progressive disclosure, cheapest first):
///   1. the block's pre-authored `why_l1_th` from the pack — instant, offline,
///      zero cost. This is the path the great majority of taps take.
///   2. the concept's authored L2, then L3 — still curriculum content, not
///      generated text, so still free and still offline.
///   3. "ถามครู AI" — would call the gateway. Not connected in this slice, and
///      the stub says so instead of inventing an answer.
///
/// It opens as a bottom sheet and never navigates: losing your place in a lesson
/// to read an explanation is the fastest way to break the habit.
Future<void> showWhySheet(
  BuildContext context, {
  required String? blockId,
  String? conceptId,
  String? fallbackL1Th,
  String? sentenceEs,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WhySheet(
      blockId: blockId,
      conceptId: conceptId,
      fallbackL1Th: fallbackL1Th,
      sentenceEs: sentenceEs,
    ),
  );
}

class WhySheet extends ConsumerStatefulWidget {
  const WhySheet({
    super.key,
    required this.blockId,
    this.conceptId,
    this.fallbackL1Th,
    this.sentenceEs,
  });

  final String? blockId;
  final String? conceptId, fallbackL1Th, sentenceEs;

  @override
  ConsumerState<WhySheet> createState() => _WhySheetState();
}

class _WhySheetState extends ConsumerState<WhySheet> {
  final List<WhyAnswer> _stack = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    final repo = ref.read(grammarRepositoryProvider);
    try {
      WhyAnswer? first;
      if (widget.blockId != null) {
        first = await repo.whyForBlock(widget.blockId!);
      }
      // Fall back to the L1 the caller already had in hand (e.g. exercise
      // feedback), then to the concept's own L1.
      if (first == null && widget.fallbackL1Th != null) {
        first = WhyAnswer(
          depth: WhyDepth.l1Simple,
          bodyTh: widget.fallbackL1Th!,
          source: 'pack',
          deeperAvailable: widget.conceptId != null,
        );
      }
      first ??= widget.conceptId == null
          ? null
          : await repo.depth(widget.conceptId!, WhyDepth.l1Simple);

      if (!mounted) return;
      setState(() {
        _loading = false;
        if (first != null) _stack.add(first);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'โหลดคำอธิบายไม่ได้';
      });
    }
  }

  WhyDepth get _nextDepth => switch (_stack.last.depth) {
        WhyDepth.l1Simple => WhyDepth.l2Understand,
        WhyDepth.l2Understand => WhyDepth.l3Deep,
        _ => WhyDepth.l4Linguistic,
      };

  String get _nextLabel => switch (_nextDepth) {
        WhyDepth.l2Understand => 'ทำไมถึงเป็นแบบนี้',
        WhyDepth.l3Deep => 'ดูละเอียด',
        _ => 'มุมมองภาษาศาสตร์',
      };

  Future<void> _deeper() async {
    if (widget.conceptId == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final next = await ref
        .read(grammarRepositoryProvider)
        .depth(widget.conceptId!, _nextDepth);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (next != null) _stack.add(next);
    });
  }

  Future<void> _askTutor() async {
    setState(() => _loadingMore = true);
    final a = await ref.read(grammarRepositoryProvider).askTutor(
          questionTh: 'ทำไมถึงใช้แบบนี้',
          conceptId: widget.conceptId,
          sentenceEs: widget.sentenceEs,
        );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      _stack.add(a);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            EdeSpace.gutter, 0, EdeSpace.gutter, EdeSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline_rounded, size: 20, color: context.colors.primary),
                const SizedBox(width: EdeSpace.sm),
                Text('ทำไม?',
                    style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
              ],
            ),
            if (_stack.isNotEmpty && _stack.first.conceptNameTh != null) ...[
              const SizedBox(height: EdeSpace.xs),
              Text(_stack.first.conceptNameTh!,
                  style: EdeType.thaiBodySmall.copyWith(color: t.inkFaint)),
            ],
            const SizedBox(height: EdeSpace.lg),
            Flexible(
              child: _loading
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EdeSkeleton(height: 14),
                        SizedBox(height: EdeSpace.sm),
                        EdeSkeleton(height: 14),
                        SizedBox(height: EdeSpace.sm),
                        EdeSkeleton(height: 14, width: 180),
                      ],
                    )
                  : _error != null
                      ? EdeErrorState(message: _error!, onRetry: _loadFirst)
                      : _stack.isEmpty
                          ? const EdeEmptyState(
                              title: 'ยังไม่มีคำอธิบายสำหรับจุดนี้',
                              body: 'ส่วนนี้ยังไม่มีคำอธิบายที่ผู้เชี่ยวชาญเขียนไว้ '
                                  'เราจะไม่แสดงคำอธิบายที่ระบบแต่งขึ้นเอง',
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < _stack.length; i++)
                                    _AnswerCard(
                                      answer: _stack[i],
                                      isFirst: i == 0,
                                    ),
                                ],
                              ),
                            ),
            ),
            if (!_loading && _stack.isNotEmpty) ...[
              const SizedBox(height: EdeSpace.lg),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.only(bottom: EdeSpace.sm),
                  child: EdeSkeleton(height: 12, width: 140),
                ),
              Wrap(
                spacing: EdeSpace.sm,
                runSpacing: EdeSpace.sm,
                children: [
                  if (widget.conceptId != null &&
                      _stack.last.deeperAvailable &&
                      _stack.last.source == 'pack')
                    EdeTextButton(
                      icon: Icons.unfold_more_rounded,
                      label: _nextLabel,
                      onPressed: _deeper,
                    ),
                  if (_stack.last.source != 'ai_stub')
                    EdeTextButton(
                      icon: Icons.school_outlined,
                      label: 'ถามครู AI',
                      onPressed: _askTutor,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.isFirst});

  final WhyAnswer answer;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isStub = answer.source == 'ai_stub';

    final depthLabel = switch (answer.depth) {
      WhyDepth.l1Simple => 'คำอธิบายสั้น',
      WhyDepth.l2Understand => 'ทำไมถึงเป็นแบบนี้',
      WhyDepth.l3Deep => 'คำอธิบายละเอียด',
      WhyDepth.l4Linguistic => 'ครู AI',
    };

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : EdeSpace.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EdeSpace.lg),
        decoration: BoxDecoration(
          color: isStub ? t.accentSurface : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(EdeRadius.control),
          border: isStub ? Border.all(color: t.accent.withValues(alpha: .4)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GrammarLabel(parts: [depthLabel]),
                if (isStub) ...[
                  const SizedBox(width: EdeSpace.sm),
                  // Never let a stub be mistaken for a real tutor answer.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('ยังไม่เชื่อมต่อ',
                        style: EdeType.label.copyWith(color: Colors.white)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: EdeSpace.sm),
            Text(answer.bodyTh,
                style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
            if (answer.spainNoteTh != null) ...[
              const SizedBox(height: EdeSpace.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.flag_outlined, size: 15, color: context.colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(answer.spainNoteTh!,
                        style: EdeType.thaiBodySmall
                            .copyWith(color: context.colors.primary)),
                  ),
                ],
              ),
            ],
            if (answer.thaiContrastTh != null) ...[
              const SizedBox(height: EdeSpace.md),
              Text(answer.thaiContrastTh!,
                  style: EdeType.thaiBodySmall.copyWith(color: t.inkSoft)),
            ],
          ],
        ),
      ),
    );
  }
}

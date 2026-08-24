import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';
import '../grammar/why_sheet.dart';
import 'speaking_view.dart';

/// Renders any exercise from its template, using the authored answer rules.
///
/// Correctness is NEVER decided here. The answer is handed to the repository,
/// which in Supabase mode calls assess.submit_attempt() and renders whatever the
/// server returns. That is what keeps the client from disagreeing with the
/// measurement layer.
class ExerciseView extends ConsumerStatefulWidget {
  const ExerciseView({
    super.key,
    required this.exerciseId,
    required this.sessionId,
    this.onGraded,
  });

  final String exerciseId;
  final String sessionId;
  final void Function(String exerciseId, bool correct)? onGraded;

  @override
  ConsumerState<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends ConsumerState<ExerciseView> {
  final _controller = TextEditingController();
  String? _choice;
  AttemptFeedback? _feedback;
  bool _submitting = false;
  String? _error;
  int _attemptNo = 0;
  DateTime? _shownAt;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasAnswer =>
      (_choice != null && _choice!.isNotEmpty) || _controller.text.trim().isNotEmpty;

  Future<void> _submit(Exercise ex) async {
    if (!_hasAnswer || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final answer = _choice ?? _controller.text.trim();

    // The attempt id is the idempotency key. A new one per *attempt*, not per
    // tap, so a retry after a dropped connection replays rather than duplicates.
    _attemptNo++;
    final attemptId = _deterministicAttemptId(ex.id, _attemptNo);

    try {
      final fb = await ref.read(attemptRepositoryProvider).submit(
            attemptId: attemptId,
            exerciseId: ex.id,
            answer: answer,
            sessionId: widget.sessionId,
            latencyMs: _shownAt == null
                ? null
                : DateTime.now().difference(_shownAt!).inMilliseconds,
          );
      if (!mounted) return;
      setState(() {
        _feedback = fb;
        _submitting = false;
      });
      widget.onGraded?.call(ex.id, fb.isCorrect);
      ref.invalidate(satisfiedProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // The learner's typing is still in the field: say so explicitly.
        _error = 'ส่งคำตอบไม่ได้ ลองอีกครั้ง — คำตอบของคุณยังไม่หาย';
      });
    }
  }

  String _deterministicAttemptId(String exerciseId, int n) {
    // UUID-shaped and stable for a given (exercise, attempt number) within this
    // widget's lifetime, so an immediate retry is idempotent server-side.
    final seed = '$exerciseId-$n'.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return '${seed.substring(0, 8)}-0000-4000-8000-${exerciseId.substring(exerciseId.length - 12)}';
  }

  void _retry() {
    setState(() {
      _feedback = null;
      _choice = null;
      _controller.clear();
      _shownAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exerciseProvider(widget.exerciseId));

    return async.when(
      loading: () => const EdeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EdeSkeleton(height: 16, width: 160),
            SizedBox(height: EdeSpace.lg),
            EdeSkeleton(height: 48),
            SizedBox(height: EdeSpace.sm),
            EdeSkeleton(height: 48),
          ],
        ),
      ),
      error: (e, _) => EdeCard(
        child: EdeErrorState(
          message: 'โหลดแบบฝึกหัดไม่ได้',
          onRetry: () => ref.invalidate(exerciseProvider(widget.exerciseId)),
        ),
      ),
      data: (ex) {
        if (ex.kind == ExerciseKind.repeatSpeech) {
          return SpeakingView(
            exercise: ex,
            sessionId: widget.sessionId,
            onDone: () => widget.onGraded?.call(ex.id, true),
          );
        }
        return EdeCard(
          padding: const EdgeInsets.all(EdeSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GrammarLabel(parts: ['ลองทำดู']),
              const SizedBox(height: EdeSpace.md),
              Text(ex.promptTh,
                  style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
              if (ex.stem != null) ...[
                const SizedBox(height: EdeSpace.md),
                Text(ex.stem!,
                    style: EdeType.spanishBody
                        .copyWith(color: context.tokens.inkSoft)),
              ],
              const SizedBox(height: EdeSpace.lg),
              if (_feedback == null) ...[
                switch (ex.kind) {
                  ExerciseKind.mcq => _McqInput(
                      options: ex.options,
                      selected: _choice,
                      onSelect: (v) => setState(() => _choice = v),
                    ),
                  ExerciseKind.typed => _TypedInput(
                      controller: _controller,
                      hintTh: ex.hintTh,
                      nameSlot: ex.hasNameSlot,
                      onChanged: (_) => setState(() {}),
                      onSubmit: () => _submit(ex),
                    ),
                  _ => Text('แบบฝึกหัดชนิดนี้ยังไม่รองรับในเวอร์ชันนี้',
                      style: EdeType.thaiBodySmall
                          .copyWith(color: context.tokens.inkFaint)),
                },
                if (_error != null) ...[
                  const SizedBox(height: EdeSpace.md),
                  Text(_error!,
                      style: EdeType.thaiBodySmall
                          .copyWith(color: context.tokens.retry)),
                ],
                const SizedBox(height: EdeSpace.lg),
                EdePrimaryButton(
                  label: 'ตรวจคำตอบ',
                  loading: _submitting,
                  onPressed: _hasAnswer ? () => _submit(ex) : null,
                ),
              ] else
                FeedbackPanel(
                  feedback: _feedback!,
                  onRetry: _retry,
                  onWhy: _feedback!.deepAvailable
                      ? () => showWhySheet(
                            context,
                            blockId: null,
                            conceptId: _feedback!.ruleConceptId,
                            fallbackL1Th: _feedback!.whyTh,
                          )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _McqInput extends StatelessWidget {
  const _McqInput({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: EdeSpace.sm),
            child: Semantics(
              button: true,
              selected: selected == o,
              child: InkWell(
                onTap: () => onSelect(o),
                borderRadius: BorderRadius.circular(EdeRadius.control),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: kMinTap + 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: EdeSpace.lg, vertical: EdeSpace.md),
                  decoration: BoxDecoration(
                    color: selected == o
                        ? context.tokens.primarySurface
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(EdeRadius.control),
                    border: Border.all(
                      color: selected == o
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                      width: selected == o ? 1.6 : 1,
                    ),
                  ),
                  // Spanish options render in the serif at readable size, and
                  // wrap rather than ellipsise: ¿Cómo se llaman ustedes? must
                  // never be truncated on a small phone.
                  child: Text(o,
                      softWrap: true,
                      style: EdeType.spanishInline
                          .copyWith(color: context.colors.onSurface)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypedInput extends StatelessWidget {
  const _TypedInput({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    this.hintTh,
    this.nameSlot = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final String? hintTh;
  final bool nameSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          style: EdeType.spanishBody.copyWith(color: context.colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Me llamo…',
            hintStyle:
                EdeType.spanishBody.copyWith(color: context.tokens.inkFaint),
            filled: true,
            fillColor: context.colors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: EdeSpace.lg, vertical: EdeSpace.lg),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EdeRadius.control),
              borderSide: BorderSide(color: context.colors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EdeRadius.control),
              borderSide: BorderSide(color: context.colors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EdeRadius.control),
              borderSide: BorderSide(color: context.colors.primary, width: 1.6),
            ),
          ),
        ),
        if (hintTh != null) ...[
          const SizedBox(height: EdeSpace.sm),
          Text(hintTh!,
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkFaint)),
        ],
        if (nameSlot) ...[
          const SizedBox(height: EdeSpace.xs),
          Text('ใส่ชื่อจริงของคุณได้เลย ระบบตรวจโครงประโยค ไม่ได้ตรวจว่าชื่ออะไร',
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkFaint)),
        ],
      ],
    );
  }
}

/// The nine-part feedback contract, rendered.
///
/// A wrong answer never says only "ผิด". It shows what the learner wrote, the
/// correct form, what changed, why, a contrasting example, and a retry — in
/// amber, not red, because a wrong answer in a lesson is normal and must not
/// read as a system failure.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.feedback,
    required this.onRetry,
    this.onWhy,
  });

  final AttemptFeedback feedback;
  final VoidCallback onRetry;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ok = feedback.isCorrect;
    final accent = ok ? t.correct : t.retry;
    final surface = ok ? t.correctSurface : t.retrySurface;

    return Container(
      key: ValueKey(ok ? 'feedback-correct' : 'feedback-incorrect'),
      width: double.infinity,
      padding: const EdgeInsets.all(EdeSpace.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(EdeRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Never colour alone: icon + text label carry the verdict.
              Icon(ok ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  size: 20, color: accent),
              const SizedBox(width: EdeSpace.sm),
              Text(ok ? 'ถูกต้อง' : 'ลองอีกครั้ง',
                  style: EdeType.thaiBody
                      .copyWith(color: accent, fontWeight: FontWeight.w600)),
              if (ok) ...[
                const SizedBox(width: EdeSpace.sm),
                Text('¡Muy bien!',
                    style: EdeType.spanishInline.copyWith(color: accent)),
              ],
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: EdeSpace.lg),
            if (feedback.yourAnswer != null)
              _Row(labelTh: 'คุณตอบ', value: feedback.yourAnswer!, dim: true),
            if (feedback.correct != null)
              _Row(labelTh: 'ที่ถูกคือ', value: feedback.correct!),
            if (feedback.whatChanged != null) ...[
              const SizedBox(height: EdeSpace.sm),
              Row(
                children: [
                  const GrammarLabel(parts: ['จุดที่ต่าง']),
                  const SizedBox(width: EdeSpace.sm),
                  Text(feedback.whatChanged!,
                      style: EdeType.spanishInline.copyWith(color: accent)),
                ],
              ),
            ],
          ],
          if (feedback.whyTh != null) ...[
            const SizedBox(height: EdeSpace.md),
            Text(feedback.whyTh!,
                style:
                    EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
          ],
          if (feedback.contrastEs != null) ...[
            const SizedBox(height: EdeSpace.md),
            Container(
              padding: const EdgeInsets.all(EdeSpace.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(EdeRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feedback.contrastEs!,
                      style: EdeType.spanishInline
                          .copyWith(color: context.colors.onSurface)),
                  if (feedback.contrastTh != null)
                    Text(feedback.contrastTh!,
                        style: EdeType.thaiBodySmall
                            .copyWith(color: context.tokens.inkSoft)),
                ],
              ),
            ),
          ],
          const SizedBox(height: EdeSpace.lg),
          Wrap(
            spacing: EdeSpace.sm,
            runSpacing: EdeSpace.sm,
            children: [
              if (!ok)
                SizedBox(
                  width: 150,
                  child: EdePrimaryButton(label: 'ลองใหม่', onPressed: onRetry),
                ),
              if (onWhy != null)
                EdeTextButton(
                    label: 'ทำไม?',
                    icon: Icons.help_outline_rounded,
                    onPressed: onWhy),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.labelTh, required this.value, this.dim = false});
  final String labelTh, value;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdeSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(labelTh,
                style: EdeType.thaiBodySmall
                    .copyWith(color: context.tokens.inkFaint)),
          ),
          Expanded(
            child: Text(value,
                style: EdeType.spanishInline.copyWith(
                  color: dim ? context.tokens.inkSoft : context.colors.onSurface,
                  decoration: dim ? TextDecoration.lineThrough : null,
                  decorationColor: context.tokens.inkFaint,
                )),
          ),
        ],
      ),
    );
  }
}

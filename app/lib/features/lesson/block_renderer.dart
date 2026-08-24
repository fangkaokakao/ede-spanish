import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';
import '../grammar/why_sheet.dart';
import '../vocabulary/word_sheet.dart';
import 'exercise_view.dart';

/// Schema-driven renderer.
///
/// The switch is exhaustive over the sealed [ContentBlock] hierarchy, so adding
/// a block type to the curriculum schema is a compile error until a renderer
/// exists. No lesson is referenced by name anywhere in this file — authoring a
/// second lesson needs no Dart change.
class BlockRenderer extends ConsumerWidget {
  const BlockRenderer({
    super.key,
    required this.block,
    required this.lessonId,
    required this.sessionId,
    this.onExerciseGraded,
  });

  final ContentBlock block;
  final String lessonId;
  final String sessionId;
  final void Function(String exerciseId, bool correct)? onExerciseGraded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = switch (block) {
      HeadingBlock(:final textTh) => _Heading(textTh),
      ExplanationBlock b => _Explanation(b),
      ExampleBlock b => _Example(b),
      PronunciationBlock b => _Pronunciation(b),
      ComparisonBlock b => _Comparison(b),
      DialogueBlock b => _Dialogue(b),
      VocabularyBlock b => _Vocabulary(b),
      ReviewBlock b => _Review(b),
      ExerciseEmbedBlock b => ExerciseView(
          key: ValueKey(b.exerciseId),
          exerciseId: b.exerciseId,
          sessionId: sessionId,
          onGraded: onExerciseGraded,
        ),
    };

    // Exercises own their whole card, including their own feedback affordances.
    if (block is ExerciseEmbedBlock) return body;

    return _BlockCard(block: block, child: body);
  }
}

/// Wraps every non-exercise block, and is the single place the ทำไม? affordance
/// is attached — so it looks and behaves identically everywhere.
class _BlockCard extends StatelessWidget {
  const _BlockCard({required this.block, required this.child});

  final ContentBlock block;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EdeCard(
      padding: const EdgeInsets.all(EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          if (block.hasWhy) ...[
            const SizedBox(height: EdeSpace.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: WhyButton(
                onTap: () => showWhySheet(
                  context,
                  blockId: block.id,
                  conceptId: block.conceptId,
                  fallbackL1Th: block.whyL1Th,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.textTh);
  final String textTh;
  @override
  Widget build(BuildContext context) => Text(textTh,
      style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface));
}

class _Explanation extends StatelessWidget {
  const _Explanation(this.b);
  final ExplanationBlock b;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (b.titleTh != null) ...[
          Text(b.titleTh!,
              style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
          const SizedBox(height: EdeSpace.sm),
        ],
        Text(b.bodyTh,
            style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
      ],
    );
  }
}

/// The Spanish sentence dominates its card; the Thai meaning is secondary; the
/// grammatical labels are tertiary. That hierarchy is carried by the type
/// system (serif / Thai sans / tracked small caps), not by colour.
class _Example extends ConsumerStatefulWidget {
  const _Example(this.b);
  final ExampleBlock b;
  @override
  ConsumerState<_Example> createState() => _ExampleState();
}

class _ExampleState extends ConsumerState<_Example> {
  bool _analysing = false;
  String? _audioNote;

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final audio = ref.read(modelAudioProvider);

    Future<bool> play(String? path, double speed) async {
      if (path == null) return false;
      final ok = await audio.play(path, speed: speed);
      if (!ok && mounted) {
        setState(() => _audioNote =
            'ยังไม่ได้ใส่ไฟล์เสียงในเวอร์ชันนี้ (ต้องวางไฟล์เสียงคนสเปนที่ assets/audio)');
      }
      return ok;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GrammarLabel(parts: ['ประโยคใหม่']),
        const SizedBox(height: EdeSpace.md),
        if (_analysing)
          SentenceAnalysis(
            tokens: b.tokens,
            fallbackEs: b.es,
            onWordTap: (w) => showWordSheet(context, word: w),
          )
        else
          SpanishLine(
            es: b.es,
            th: b.th,
            onTapWord: (w) => showWordSheet(context, word: w),
          ),
        if (b.naturalNoteTh != null) ...[
          const SizedBox(height: EdeSpace.md),
          Text(b.naturalNoteTh!,
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkSoft)),
        ],
        const SizedBox(height: EdeSpace.lg),
        AudioControls(
          onNormal: () => play(b.audio.normal, 1.0),
          onSlow: () => play(b.audio.slow ?? b.audio.normal, 0.75),
          unavailableNote: _audioNote,
        ),
        if (b.tokens.isNotEmpty) ...[
          const SizedBox(height: EdeSpace.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: EdeTextButton(
              icon: _analysing ? Icons.close_rounded : Icons.account_tree_outlined,
              label: _analysing ? 'ปิดการแยกคำ' : 'กดแยกคำ',
              onPressed: () => setState(() => _analysing = !_analysing),
            ),
          ),
        ],
      ],
    );
  }
}

class _Pronunciation extends ConsumerStatefulWidget {
  const _Pronunciation(this.b);
  final PronunciationBlock b;
  @override
  ConsumerState<_Pronunciation> createState() => _PronunciationState();
}

class _PronunciationState extends ConsumerState<_Pronunciation> {
  String? _note;

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final audio = ref.read(modelAudioProvider);

    Future<bool> play(String? path, double speed) async {
      if (path == null) return false;
      final ok = await audio.play(path, speed: speed);
      if (!ok && mounted) {
        setState(() => _note = 'ยังไม่ได้ใส่ไฟล์เสียงในเวอร์ชันนี้');
      }
      return ok;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrammarLabel(parts: ['การออกเสียง', b.focus]),
        const SizedBox(height: EdeSpace.md),
        // Phonemic and phonetic are shown separately because they are different
        // claims: one is about the variety, one about this recording.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(b.focus,
                style: EdeType.spanishDisplay
                    .copyWith(color: context.colors.onSurface)),
            const SizedBox(width: EdeSpace.md),
            if (b.ipaPhonemic != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: EdeSpace.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: context.tokens.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('/${b.ipaPhonemic}/',
                    style: EdeType.numeric.copyWith(color: context.colors.primary)),
              ),
          ],
        ),
        const SizedBox(height: EdeSpace.md),
        Text(b.noteTh,
            style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
        if (b.contrastA != null && b.contrastB != null) ...[
          const SizedBox(height: EdeSpace.lg),
          Container(
            padding: const EdgeInsets.all(EdeSpace.lg),
            decoration: BoxDecoration(
              color: context.tokens.retrySurface,
              borderRadius: BorderRadius.circular(EdeRadius.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(b.contrastA!,
                        style: EdeType.spanishInline
                            .copyWith(color: context.tokens.retry)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: EdeSpace.sm),
                      child: Text('≠',
                          style: TextStyle(color: context.tokens.retry)),
                    ),
                    Text(b.contrastB!,
                        style: EdeType.spanishInline
                            .copyWith(color: context.tokens.retry)),
                  ],
                ),
                if (b.contrastNoteTh != null) ...[
                  const SizedBox(height: EdeSpace.xs),
                  Text(b.contrastNoteTh!,
                      style: EdeType.thaiBodySmall
                          .copyWith(color: context.colors.onSurface)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: EdeSpace.lg),
        AudioControls(
          onNormal: () => play(b.audio.normal, 1.0),
          onSlow: () => play(b.audio.slow ?? b.audio.normal, 0.7),
          unavailableNote: _note,
        ),
      ],
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison(this.b);
  final ComparisonBlock b;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.titleTh,
            style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
        const SizedBox(height: EdeSpace.lg),
        for (final r in b.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: EdeSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.labelTh,
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.tokens.inkSoft)),
                    ),
                    _RegisterTag(r.register),
                  ],
                ),
                const SizedBox(height: 4),
                Text(r.es,
                    style: EdeType.spanishBody
                        .copyWith(color: context.colors.onSurface)),
              ],
            ),
          ),
        if (b.noteTh != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdeSpace.lg),
            decoration: BoxDecoration(
              color: context.tokens.primarySurface,
              borderRadius: BorderRadius.circular(EdeRadius.control),
            ),
            child: Text(b.noteTh!,
                style: EdeType.thaiBodySmall
                    .copyWith(color: context.colors.onSurface)),
          ),
      ],
    );
  }
}

/// Register is always visible, because "correct but wrong register" is one of
/// the fastest ways to sound odd in Spain.
class _RegisterTag extends StatelessWidget {
  const _RegisterTag(this.register);
  final String register;

  @override
  Widget build(BuildContext context) {
    final labelTh = switch (register) {
      'formal' => 'สุภาพ',
      'formal_high' => 'สุภาพมาก',
      'informal' => 'กันเอง',
      'colloquial' => 'ภาษาพูด',
      'slang' => 'สแลง',
      'professional' => 'ทางการ/งาน',
      'administrative' => 'ราชการ',
      _ => 'กลาง',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Text(labelTh,
          style: EdeType.thaiBodySmall
              .copyWith(fontSize: 11.5, color: context.tokens.inkFaint)),
    );
  }
}

class _Dialogue extends StatelessWidget {
  const _Dialogue(this.b);
  final DialogueBlock b;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.titleTh,
            style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
        const SizedBox(height: EdeSpace.lg),
        for (final t in b.turns)
          Padding(
            padding: const EdgeInsets.only(bottom: EdeSpace.md),
            child: Align(
              alignment:
                  t.speaker == 'A' ? Alignment.centerLeft : Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                child: Container(
                  padding: const EdgeInsets.all(EdeSpace.lg),
                  decoration: BoxDecoration(
                    color: t.speaker == 'A'
                        ? context.colors.surfaceContainerLowest
                        : context.tokens.primarySurface,
                    borderRadius: BorderRadius.circular(EdeRadius.control),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.es,
                          style: EdeType.spanishInline
                              .copyWith(color: context.colors.onSurface)),
                      const SizedBox(height: 4),
                      Text(t.th,
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.tokens.inkSoft)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (b.noteTh != null) ...[
          const SizedBox(height: EdeSpace.sm),
          Text(b.noteTh!,
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkSoft)),
        ],
      ],
    );
  }
}

class _Vocabulary extends ConsumerWidget {
  const _Vocabulary(this.b);
  final VocabularyBlock b;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sensesProvider(b.senseIds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.titleTh,
            style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
        const SizedBox(height: EdeSpace.lg),
        async.when(
          loading: () => const Column(
            children: [
              EdeSkeleton(height: 44),
              SizedBox(height: EdeSpace.sm),
              EdeSkeleton(height: 44),
            ],
          ),
          error: (e, _) => Text('โหลดคำศัพท์ไม่ได้',
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.retry)),
          data: (senses) => senses.isEmpty
              ? Text('ยังไม่มีคำศัพท์ในบทนี้',
                  style:
                      EdeType.thaiBodySmall.copyWith(color: context.tokens.inkFaint))
              : Column(
                  children: [
                    for (final s in senses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: EdeSpace.sm),
                        child: InkWell(
                          onTap: () => showWordSheet(context, sense: s),
                          borderRadius: BorderRadius.circular(EdeRadius.control),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: kMinTap),
                            padding: const EdgeInsets.symmetric(
                                horizontal: EdeSpace.md, vertical: EdeSpace.sm),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.articleHint,
                                          style: EdeType.spanishInline.copyWith(
                                              color: context.colors.onSurface)),
                                      Text(s.meaningTh,
                                          style: EdeType.thaiBodySmall.copyWith(
                                              color: context.tokens.inkSoft)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: context.tokens.inkFaint),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review(this.b);
  final ReviewBlock b;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(b.titleTh,
            style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
        const SizedBox(height: EdeSpace.md),
        for (final p in b.pointsTh)
          Padding(
            padding: const EdgeInsets.only(bottom: EdeSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: EdeSpace.md),
                  child: AzulejoTile(size: 12, progress: 1),
                ),
                Expanded(
                  child: Text(p,
                      style: EdeType.thaiBody
                          .copyWith(color: context.colors.onSurface)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'components.dart';
import 'learning_widgets.dart';
import 'theme.dart';
import 'tokens.dart';

/// The polished, reusable pronunciation presentation used throughout
/// Foundation 0 (and any later sound lesson).
///
/// Progressive disclosure: the target sound, its IPA, the Thai articulation
/// note, and the audio controls are always visible — that is the minimum a
/// learner needs. The example word, syllable segmentation, and contrast pair
/// sit behind a single "ทำไมออกเสียงแบบนี้?" toggle so a simple card (e.g. a
/// bare vowel) never looks more complicated than it needs to.
class PronunciationCard extends StatefulWidget {
  const PronunciationCard({
    super.key,
    required this.focus,
    this.ipaPhonemic,
    this.ipaPhonetic,
    required this.noteTh,
    this.thaiHelperTh,
    this.exampleEs,
    this.exampleTh,
    this.syllables = const [],
    this.contrastA,
    this.contrastB,
    this.contrastNoteTh,
    this.showSpainBadge = false,
    this.thaiProminence = 1.0,
    required this.onPlayNormal,
    required this.onPlaySlow,
    this.unavailableNote,
  });

  /// The letter, digraph, or short target being taught (e.g. "z", "e", "rr").
  final String focus;
  final String? ipaPhonemic, ipaPhonetic;

  /// Concise Thai articulation hint — always shown, this is the explanation
  /// of *how* to make the sound, not a transliteration of it.
  final String noteTh;

  /// Optional Thai transliteration bridge (e.g. "โอ-ลา"). Null means this
  /// sound has no good Thai equivalent — the card says so explicitly instead
  /// of forcing an inaccurate transcription.
  final String? thaiHelperTh;

  final String? exampleEs, exampleTh;
  final List<String> syllables;
  final String? contrastA, contrastB, contrastNoteTh;

  /// Only set where it adds real contrast (distinción, yeísmo) — not on
  /// every card.
  final bool showSpainBadge;

  /// 0..1. Fades the Thai helper as a learner advances, so it earns its
  /// place next to the Spanish rather than permanently competing with it.
  final double thaiProminence;

  final Future<bool> Function() onPlayNormal;
  final Future<bool> Function() onPlaySlow;
  final String? unavailableNote;

  @override
  State<PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends State<PronunciationCard> {
  bool _expanded = false;

  bool get _hasDisclosure =>
      (widget.exampleEs != null && widget.exampleEs!.isNotEmpty) ||
      widget.syllables.isNotEmpty ||
      (widget.contrastA != null && widget.contrastB != null);

  @override
  Widget build(BuildContext context) {
    final prominence = widget.thaiProminence.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: GrammarLabel(parts: ['การออกเสียง', widget.focus])),
            if (widget.showSpainBadge) const _SpainBadge(),
          ],
        ),
        const SizedBox(height: EdeSpace.md),
        // Phonemic and phonetic are shown separately because they are
        // different claims: one is about the variety, one about this
        // recording.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.focus,
                style: EdeType.spanishDisplay
                    .copyWith(color: context.colors.onSurface)),
            if (widget.ipaPhonemic != null) ...[
              const SizedBox(width: EdeSpace.md),
              _IpaChip('/${widget.ipaPhonemic}/'),
            ],
          ],
        ),
        const SizedBox(height: EdeSpace.md),
        Text(widget.noteTh,
            style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
        const SizedBox(height: EdeSpace.lg),
        _ThaiHelper(text: widget.thaiHelperTh, prominence: prominence),
        const SizedBox(height: EdeSpace.lg),
        AudioControls(
          onNormal: widget.onPlayNormal,
          onSlow: widget.onPlaySlow,
          unavailableNote: widget.unavailableNote,
        ),
        if (_hasDisclosure) ...[
          const SizedBox(height: EdeSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: EdeTextButton(
              icon: _expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              label: 'ทำไมออกเสียงแบบนี้?',
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          AnimatedSize(
            duration: EdeMotion.standard,
            curve: EdeMotion.curve,
            alignment: Alignment.topLeft,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: EdeSpace.sm),
                    child: _Disclosure(
                      exampleEs: widget.exampleEs,
                      exampleTh: widget.exampleTh,
                      syllables: widget.syllables,
                      contrastA: widget.contrastA,
                      contrastB: widget.contrastB,
                      contrastNoteTh: widget.contrastNoteTh,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _IpaChip extends StatelessWidget {
  const _IpaChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.tokens.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: EdeType.numeric.copyWith(color: context.colors.primary)),
    );
  }
}

/// The small saffron badge marking a Spain-vs-Latin-America contrast. Used
/// sparingly — only where the sound actually differs from a widely-used
/// Latin American norm (distinción, yeísmo), never as generic decoration.
class _SpainBadge extends StatelessWidget {
  const _SpainBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.tokens.accentSurface,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        border: Border.all(color: context.tokens.accent.withValues(alpha: .4)),
      ),
      child: Text('สเปน',
          style: EdeType.label.copyWith(color: context.tokens.accent)),
    );
  }
}

/// The structured Thai pronunciation aid. Present when a transliteration
/// bridge exists; otherwise says plainly that Thai has no good match for this
/// sound, so the learner listens and imitates instead of anchoring on an
/// inaccurate approximation.
class _ThaiHelper extends StatelessWidget {
  const _ThaiHelper({required this.text, required this.prominence});
  final String? text;
  final double prominence;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (text == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EdeSpace.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(EdeRadius.control),
        ),
        child: Text(
          'เสียงนี้ไม่มีเสียงเทียบเท่าที่ตรงในภาษาไทย — ฟังต้นแบบแล้วเลียนเสียงโดยตรง '
          'แทนการเทียบเสียงไทย',
          style: EdeType.thaiBodySmall.copyWith(color: t.inkSoft),
        ),
      );
    }

    // Fades toward a quieter treatment as prominence drops, so the helper
    // earns its place next to the Spanish rather than permanently competing
    // with it.
    final faded = prominence < 0.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.md, vertical: EdeSpace.sm),
      decoration: BoxDecoration(
        color: t.accentSurface.withValues(alpha: 0.4 + 0.6 * prominence),
        borderRadius: BorderRadius.circular(EdeRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(text!,
              style: (faded ? EdeType.thaiBodySmall : EdeType.thaiBody).copyWith(
                color: faded ? t.inkFaint : t.accent,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: EdeSpace.sm),
          Flexible(
            child: Text('คำเทียบเสียงแบบไทย ไม่ใช่เสียงที่เหมือนกันทุกประการ',
                style: EdeType.thaiBodySmall.copyWith(color: t.inkFaint)),
          ),
        ],
      ),
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({
    required this.exampleEs,
    required this.exampleTh,
    required this.syllables,
    required this.contrastA,
    required this.contrastB,
    required this.contrastNoteTh,
  });

  final String? exampleEs, exampleTh;
  final List<String> syllables;
  final String? contrastA, contrastB, contrastNoteTh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdeSpace.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(EdeRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exampleEs != null) ...[
            const GrammarLabel(parts: ['คำตัวอย่าง']),
            const SizedBox(height: EdeSpace.xs),
            Text(exampleEs!,
                style: EdeType.spanishInline
                    .copyWith(color: context.colors.onSurface)),
            if (exampleTh != null)
              Text(exampleTh!,
                  style:
                      EdeType.thaiBodySmall.copyWith(color: context.tokens.inkSoft)),
          ],
          if (syllables.isNotEmpty) ...[
            const SizedBox(height: EdeSpace.md),
            const GrammarLabel(parts: ['แบ่งพยางค์']),
            const SizedBox(height: EdeSpace.xs),
            Wrap(
              spacing: EdeSpace.xs,
              children: [
                for (var i = 0; i < syllables.length; i++) ...[
                  if (i > 0)
                    Text('·', style: TextStyle(color: context.tokens.inkFaint)),
                  Text(syllables[i],
                      style: EdeType.spanishInline
                          .copyWith(color: context.colors.onSurface)),
                ],
              ],
            ),
          ],
          if (contrastA != null && contrastB != null) ...[
            const SizedBox(height: EdeSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(EdeSpace.md),
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
                      Text(contrastA!,
                          style: EdeType.spanishInline
                              .copyWith(color: context.tokens.retry)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: EdeSpace.sm),
                        child: Text('≠',
                            style: TextStyle(color: context.tokens.retry)),
                      ),
                      Text(contrastB!,
                          style: EdeType.spanishInline
                              .copyWith(color: context.tokens.retry)),
                    ],
                  ),
                  if (contrastNoteTh != null) ...[
                    const SizedBox(height: EdeSpace.xs),
                    Text(contrastNoteTh!,
                        style: EdeType.thaiBodySmall
                            .copyWith(color: context.colors.onSurface)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

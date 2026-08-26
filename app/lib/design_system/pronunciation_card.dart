import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/entities.dart';
import 'components.dart';
import 'learning_widgets.dart';
import 'theme.dart';
import 'tokens.dart';

/// The reusable pronunciation presentation: focus + IPA, an optional Thai
/// pronunciation-bridge helper (or an explicit "no equivalent" note),
/// audio controls, and a progressive "ทำไมออกเสียงแบบนี้?" disclosure that
/// reveals the fuller articulation note, a worked example, and a minimal-pair
/// contrast where one exists.
///
/// Deliberately does not show every field at once (per product direction):
/// the Spain-vs-other-variety badge only appears when [PronunciationBlock.
/// showSpainBadge] is true, and the example/contrast stay behind the
/// disclosure toggle rather than always-on.
class PronunciationCard extends ConsumerStatefulWidget {
  const PronunciationCard({super.key, required this.block});
  final PronunciationBlock block;

  @override
  ConsumerState<PronunciationCard> createState() => _PronunciationCardState();
}

class _PronunciationCardState extends ConsumerState<PronunciationCard> {
  bool _expanded = false;
  String? _audioNote;

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    // Fail open (show the helper) while preferences are still loading, so a
    // beginner is never silently left without the bridge on first paint.
    final showThaiHelp =
        ref.watch(preferencesProvider).valueOrNull?.showThaiPronunciationHelp ??
            true;
    final audio = ref.read(modelAudioProvider);

    Future<bool> play(String? path, double speed) async {
      if (path == null) return false;
      final ok = await audio.play(path, speed: speed);
      if (!ok && mounted) {
        setState(() => _audioNote = 'ยังไม่ได้ใส่ไฟล์เสียงในเวอร์ชันนี้');
      }
      return ok;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrammarLabel(parts: ['การออกเสียง', b.focus]),
        const SizedBox(height: EdeSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(b.focus,
                  style: EdeType.spanishDisplay
                      .copyWith(color: context.colors.onSurface)),
            ),
            if (b.ipaPhonemic != null) ...[
              _IpaBadge(b.ipaPhonemic!),
              const SizedBox(width: EdeSpace.sm),
            ],
            if (b.showSpainBadge) const _SpainBadge(),
          ],
        ),
        const SizedBox(height: EdeSpace.lg),
        if (showThaiHelp) ...[
          _ThaiHelperBox(block: b),
          const SizedBox(height: EdeSpace.lg),
        ],
        AudioControls(
          onNormal: () => play(b.audio.normal, 1.0),
          onSlow: () => play(b.audio.slow ?? b.audio.normal, 0.7),
          unavailableNote: _audioNote,
        ),
        const SizedBox(height: EdeSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: EdeTextButton(
            icon:
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            label: 'ทำไมออกเสียงแบบนี้?',
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        AnimatedSize(
          duration: EdeMotion.standard,
          curve: EdeMotion.curve,
          alignment: Alignment.topLeft,
          child: _expanded
              ? _Disclosure(block: b)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _IpaBadge extends StatelessWidget {
  const _IpaBadge(this.phoneme);
  final String phoneme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: context.tokens.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('/$phoneme/',
          style: EdeType.numeric.copyWith(color: context.colors.primary)),
    );
  }
}

/// "สเปน" — shown only when a card exists to contrast Spain Spanish against
/// another variety (distinción, yeísmo). A plain vowel/letter sound has
/// nothing to contrast, so it never carries this badge.
class _SpainBadge extends StatelessWidget {
  const _SpainBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm, vertical: 4),
      decoration: BoxDecoration(
        color: context.tokens.accentSurface,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        border: Border.all(color: context.tokens.accent.withValues(alpha: .5)),
      ),
      child: Text('สเปน',
          style: EdeType.label.copyWith(color: context.tokens.accent)),
    );
  }
}

/// The Thai pronunciation-bridge helper, or — when the sound has no honest
/// Thai equivalent — an explicit note saying so instead of a misleading
/// transliteration. Never claims the two languages sound the same.
class _ThaiHelperBox extends StatelessWidget {
  const _ThaiHelperBox({required this.block});
  final PronunciationBlock block;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final helper = block.thaiHelperTh;

    if (helper == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EdeSpace.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(EdeRadius.control),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Text(
          block.noEquivalentNoteTh ??
              'เสียงนี้ไม่มีเสียงเทียบเท่าที่ตรงกันในภาษาไทย ลองฟังเสียงจริงแล้วเลียนเสียงตามแทนการอ่านคำเทียบ',
          style: EdeType.thaiBodySmall.copyWith(color: t.inkSoft),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdeSpace.lg),
      decoration: BoxDecoration(
        color: t.accentSurface,
        borderRadius: BorderRadius.circular(EdeRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('คำอ่านช่วย'.toUpperCase(),
              style: EdeType.label.copyWith(color: t.accent)),
          const SizedBox(height: 4),
          Text(helper,
              style:
                  EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
          const SizedBox(height: 4),
          Text(
            'เป็นเสียงเทียบเคียงจากภาษาไทยเพื่อช่วยจำเท่านั้น ไม่ใช่เสียงที่เหมือนกันทุกประการ',
            style: EdeType.thaiBodySmall.copyWith(color: t.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Disclosure extends StatelessWidget {
  const _Disclosure({required this.block});
  final PronunciationBlock block;

  @override
  Widget build(BuildContext context) {
    final b = block;
    return Padding(
      padding: const EdgeInsets.only(top: EdeSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.noteTh,
              style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
          if (b.exampleEs != null) ...[
            const SizedBox(height: EdeSpace.lg),
            _ExampleCard(block: b),
          ],
          if (b.contrastA != null && b.contrastB != null) ...[
            const SizedBox(height: EdeSpace.lg),
            _ContrastPair(block: b),
          ],
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.block});
  final PronunciationBlock block;

  @override
  Widget build(BuildContext context) {
    final b = block;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdeSpace.lg),
      decoration: BoxDecoration(
        color: context.tokens.primarySurface,
        borderRadius: BorderRadius.circular(EdeRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GrammarLabel(parts: ['ตัวอย่าง']),
          const SizedBox(height: EdeSpace.sm),
          Text(
            b.exampleSyllables.isNotEmpty
                ? b.exampleSyllables.join('-')
                : b.exampleEs!,
            style:
                EdeType.spanishBody.copyWith(color: context.colors.onSurface),
          ),
          if (b.exampleReadingTh != null) ...[
            const SizedBox(height: 4),
            Text('ช่วยอ่าน: ${b.exampleReadingTh}',
                style: EdeType.thaiBodySmall
                    .copyWith(color: context.tokens.inkSoft)),
          ],
          if (b.exampleMeaningTh != null) ...[
            const SizedBox(height: 4),
            Text('ความหมาย: ${b.exampleMeaningTh}',
                style: EdeType.thaiBodySmall
                    .copyWith(color: context.tokens.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class _ContrastPair extends StatelessWidget {
  const _ContrastPair({required this.block});
  final PronunciationBlock block;

  @override
  Widget build(BuildContext context) {
    final b = block;
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: EdeSpace.sm),
                child:
                    Text('≠', style: TextStyle(color: context.tokens.retry)),
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
    );
  }
}

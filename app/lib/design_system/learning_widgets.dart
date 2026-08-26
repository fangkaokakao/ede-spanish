import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/entities.dart';
import 'components.dart';
import 'theme.dart';
import 'tokens.dart';

/// Audio controls for a Spanish line. Icons always carry a text label — a
/// beginner should never have to guess what a control does.
class AudioControls extends StatelessWidget {
  const AudioControls({
    super.key,
    required this.onNormal,
    required this.onSlow,
    this.playing = false,
    this.unavailableNote,
  });

  final Future<bool> Function() onNormal;
  final Future<bool> Function() onSlow;
  final bool playing;

  /// Shown when the audio asset is not bundled yet, instead of failing silently.
  final String? unavailableNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: EdeSpace.sm,
          runSpacing: EdeSpace.sm,
          children: [
            AudioButton(playing: playing, onPlay: () => onNormal()),
            AudioButton(slow: true, onPlay: () => onSlow()),
          ],
        ),
        if (unavailableNote != null) ...[
          const SizedBox(height: EdeSpace.sm),
          Text(unavailableNote!,
              style: EdeType.thaiBodySmall.copyWith(color: context.tokens.inkFaint)),
        ],
      ],
    );
  }
}

/// Tap-to-analyse sentence. Each token is a target; tapping reveals its role and
/// morphological segmentation. This is the interaction that turns a sentence
/// from something to memorise into something to understand.
class SentenceAnalysis extends StatefulWidget {
  const SentenceAnalysis({
    super.key,
    required this.tokens,
    required this.fallbackEs,
    this.onWordTap,
  });

  final List<Token> tokens;
  final String fallbackEs;
  final void Function(String word)? onWordTap;

  @override
  State<SentenceAnalysis> createState() => _SentenceAnalysisState();
}

class _SentenceAnalysisState extends State<SentenceAnalysis> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.tokens.isEmpty) {
      return Text(widget.fallbackEs,
          style: EdeType.spanishDisplay.copyWith(color: context.colors.onSurface));
    }

    final sel = _selected == null ? null : widget.tokens[_selected!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: EdeSpace.xs,
          runSpacing: EdeSpace.sm,
          children: [
            for (var i = 0; i < widget.tokens.length; i++)
              _TokenChip(
                token: widget.tokens[i],
                selected: _selected == i,
                onTap: () {
                  setState(() => _selected = _selected == i ? null : i);
                  widget.onWordTap?.call(widget.tokens[i].text);
                },
              ),
          ],
        ),
        AnimatedSize(
          duration: EdeMotion.standard,
          curve: EdeMotion.curve,
          alignment: Alignment.topLeft,
          child: sel == null
              ? Padding(
                  padding: const EdgeInsets.only(top: EdeSpace.md),
                  child: Text('แตะคำเพื่อดูว่าแต่ละคำทำหน้าที่อะไร',
                      style: EdeType.thaiBodySmall
                          .copyWith(color: context.tokens.inkFaint)),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: EdeSpace.lg),
                  child: _TokenDetail(token: sel),
                ),
        ),
      ],
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.token, required this.selected, required this.onTap});

  final Token token;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${token.text}${token.role == null ? '' : ', ${token.role}'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        child: AnimatedContainer(
          selected: selected,
          child: Text(token.text,
              style: EdeType.spanishBody.copyWith(
                color: selected ? context.colors.primary : context.colors.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
        ),
      ),
    );
  }
}

/// Small helper so the chip animation lives in one place.
class AnimatedContainer extends StatelessWidget {
  const AnimatedContainer({super.key, required this.selected, required this.child});
  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: kMinTap - 8),
      padding: const EdgeInsets.symmetric(
          horizontal: EdeSpace.md, vertical: EdeSpace.sm),
      decoration: BoxDecoration(
        color: selected ? context.tokens.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        border: Border.all(
          color: selected
              ? context.colors.primary.withValues(alpha: .55)
              : context.colors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

class _TokenDetail extends StatelessWidget {
  const _TokenDetail({required this.token});
  final Token token;

  @override
  Widget build(BuildContext context) {
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
          Text(token.text,
              style: EdeType.spanishBody.copyWith(color: context.colors.onSurface)),
          if (token.role != null) ...[
            const SizedBox(height: EdeSpace.xs),
            GrammarLabel(parts: [token.role!]),
          ],
          if (token.segments.isNotEmpty) ...[
            const SizedBox(height: EdeSpace.lg),
            const GrammarLabel(parts: ['แยกส่วนของคำ']),
            const SizedBox(height: EdeSpace.sm),
            for (final s in token.segments)
              Padding(
                padding: const EdgeInsets.only(bottom: EdeSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: EdeSpace.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s.text,
                          style: EdeType.spanishInline
                              .copyWith(color: context.colors.primary)),
                    ),
                    const SizedBox(width: EdeSpace.md),
                    Expanded(
                      child: Text(s.glossTh,
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.colors.onSurface)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Progress along a unit, drawn with the azulejo motif so completion reads as
/// the tile completing rather than as a number going up.
class AzulejoProgressRow extends StatelessWidget {
  const AzulejoProgressRow({
    super.key,
    required this.total,
    required this.completed,
    required this.currentIndex,
  });

  final int total, completed, currentIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ความคืบหน้า $completed จาก $total บทเรียน',
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: const EdgeInsets.only(right: EdeSpace.sm),
              child: AzulejoTile(
                size: 28,
                progress: i < completed ? 1 : (i == currentIndex ? 0.5 : 0),
                locked: i > currentIndex,
                highlight: i == currentIndex,
              ),
            ),
        ],
      ),
    );
  }
}

/// A single outstanding-requirement chip, so the learner always knows what is
/// still owed before a lesson counts as complete.
class RequirementChip extends StatelessWidget {
  const RequirementChip({super.key, required this.labelTh, required this.done});
  final String labelTh;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: EdeSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: done ? t.correctSurface : context.colors.surface,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        border: Border.all(color: done ? t.correct : context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_rounded : Icons.circle_outlined,
              size: 14, color: done ? t.correct : t.inkFaint),
          const SizedBox(width: 6),
          Text(labelTh,
              style: EdeType.thaiBodySmall
                  .copyWith(color: done ? t.correct : t.inkSoft)),
        ],
      ),
    );
  }
}

/// Sets the frame for Foundation 0's whole course map, so a learner opening it
/// immediately understands: "ฉันกำลังเรียนเสียงและการอ่านก่อนเริ่มภาษาสเปนจริง".
class FoundationSoundIntroBanner extends StatelessWidget {
  const FoundationSoundIntroBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
          const GrammarLabel(parts: ['Foundation 0', 'เสียงและการอ่าน']),
          const SizedBox(height: EdeSpace.sm),
          Text(
            'ก่อนเริ่มภาษาสเปนจริง คุณจะได้เรียนรู้ตัวอักษร เสียง และวิธีอ่านออกเสียงให้แน่นก่อน '
            'ยังไม่ใช่บทสนทนา — เรียนจบหมวดนี้แล้วค่อยไปทักทายและแนะนำตัวใน Pre-A1',
            style:
                EdeType.thaiBody.copyWith(color: context.colors.onSurface),
          ),
        ],
      ),
    );
  }
}

/// "แสดงคำอ่านไทย" — lets the learner turn the Thai pronunciation-bridge
/// helper on [PronunciationCard] on or off. On by default for absolute
/// beginners.
class ThaiHelperToggle extends ConsumerWidget {
  const ThaiHelperToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).valueOrNull;
    final enabled = prefs?.showThaiPronunciationHelp ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EdeSpace.lg, vertical: EdeSpace.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('แสดงคำอ่านไทยช่วยจำ',
                style: EdeType.thaiBody
                    .copyWith(color: context.colors.onSurface)),
          ),
          Switch(
            value: enabled,
            onChanged: prefs == null
                ? null
                : (v) async {
                    await ref.read(learnerRepositoryProvider).savePreferences(
                        prefs.copyWith(showThaiPronunciationHelp: v));
                    ref.invalidate(preferencesProvider);
                  },
          ),
        ],
      ),
    );
  }
}

/// Banner shown whenever the app is running without a backend, so a reviewer is
/// never misled about what is real.
class LocalModeBanner extends StatelessWidget {
  const LocalModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: EdeSpace.gutter, vertical: EdeSpace.sm),
      color: context.tokens.accentSurface,
      child: Text(
        'โหมดพัฒนา (local) — ยังไม่เชื่อมต่อฐานข้อมูล การตรวจคำตอบใช้กฎเดียวกับ server',
        style: EdeType.thaiBodySmall.copyWith(color: context.tokens.accent),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'tokens.dart';

// ============================================================== SIGNATURE ==

/// The one memorable element. A four-fold azulejo tile, drawn rather than
/// imaged so it scales, themes, and stays a few hundred bytes.
///
/// It carries information rather than decorating: [progress] fills the petals
/// clockwise, so a unit marker on the course map shows completion *as the tile
/// completing*. A locked unit is an empty outline; a finished unit is a whole
/// tile. Nothing else in the product uses this shape.
class AzulejoTile extends StatelessWidget {
  const AzulejoTile({
    super.key,
    this.size = 56,
    this.progress = 0,
    this.locked = false,
    this.highlight = false,
  });

  final double size;
  final double progress; // 0..1
  final bool locked;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AzulejoPainter(
          progress: progress.clamp(0, 1),
          base: locked ? t.hairline : context.colors.primary.withValues(alpha: .22),
          fill: highlight ? t.accent : context.colors.primary,
          locked: locked,
        ),
      ),
    );
  }
}

class _AzulejoPainter extends CustomPainter {
  _AzulejoPainter({
    required this.progress,
    required this.base,
    required this.fill,
    required this.locked,
  });

  final double progress;
  final Color base;
  final Color fill;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Four petals meeting at the centre — the core azulejo quatrefoil.
    Path petal(double angle) {
      final p = Path();
      final a = angle * math.pi / 180;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r * 0.94;
      final l = c + Offset(math.cos(a - 0.9), math.sin(a - 0.9)) * r * 0.42;
      final rr = c + Offset(math.cos(a + 0.9), math.sin(a + 0.9)) * r * 0.42;
      p.moveTo(c.dx, c.dy);
      p.quadraticBezierTo(l.dx, l.dy, tip.dx, tip.dy);
      p.quadraticBezierTo(rr.dx, rr.dy, c.dx, c.dy);
      return p;
    }

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = base;
    final solid = Paint()..color = fill;

    for (var i = 0; i < 4; i++) {
      final p = petal(45 + i * 90);
      canvas.drawPath(p, outline);
      // Each petal is a quarter of progress: the tile completes as the unit does.
      final share = ((progress * 4) - i).clamp(0.0, 1.0);
      if (share > 0) {
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawPath(p, solid);
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * (1 - share), size.width, size.height),
          Paint()..blendMode = BlendMode.dstIn,
        );
        canvas.restore();
      }
    }

    canvas.drawCircle(c, r * 0.13,
        Paint()..color = progress >= 1 ? fill : base);
  }

  @override
  bool shouldRepaint(_AzulejoPainter old) =>
      old.progress != progress || old.fill != fill || old.locked != locked;
}

// ================================================================ BUTTONS ==

/// Exactly one of these per screen. If a screen needs two, the screen is wrong.
class EdePrimaryButton extends StatelessWidget {
  const EdePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          disabledBackgroundColor: context.colors.primary.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EdeRadius.control),
          ),
          textStyle: EdeType.button,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: EdeSpace.sm)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary actions never compete: text weight, no fill.
class EdeTextButton extends StatelessWidget {
  const EdeTextButton({super.key, required this.label, this.icon, this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.colors.primary,
        minimumSize: const Size(0, kMinTap),
        padding: const EdgeInsets.symmetric(horizontal: EdeSpace.md),
        textStyle: EdeType.button.copyWith(fontSize: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
  }
}

// ================================================================== TEXT ====

/// A Spanish sentence with its Thai meaning beneath.
///
/// The `Semantics` locale matters more than it looks: without it, TalkBack and
/// VoiceOver read Spanish with a Thai voice, which is unusable. Screen-reader
/// support for a bilingual app is a script-switching problem, not a labels problem.
class SpanishLine extends StatelessWidget {
  const SpanishLine({
    super.key,
    required this.es,
    this.th,
    this.style,
    this.onTapWord,
  });

  final String es;
  final String? th;
  final TextStyle? style;
  final void Function(String word)? onTapWord;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? EdeType.spanishDisplay).copyWith(color: context.colors.onSurface);

    Widget spanish = Semantics(
      attributedLabel: AttributedString(es),
      child: onTapWord == null
          ? Text(es, style: base)
          : Wrap(
              spacing: 0,
              children: [
                for (final w in es.split(' '))
                  _TappableWord(word: w, style: base, onTap: () => onTapWord!(_strip(w))),
              ],
            ),
    );

    if (th == null) return spanish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spanish,
        const SizedBox(height: EdeSpace.sm),
        Text(th!, style: EdeType.thaiBody.copyWith(color: context.tokens.inkSoft)),
      ],
    );
  }

  static String _strip(String w) =>
      w.replaceAll(RegExp(r'''[.,¿?¡!;:"“”]'''), '');
}

class _TappableWord extends StatelessWidget {
  const _TappableWord({required this.word, required this.style, required this.onTap});

  final String word;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border(
            bottom: BorderSide(
              color: context.colors.primary.withValues(alpha: .28),
              width: 1.5,
            ),
          ),
        ),
        child: Text(word, style: style),
      ),
    );
  }
}

/// "sustantivo · masculino · singular"
class GrammarLabel extends StatelessWidget {
  const GrammarLabel({super.key, required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) => Text(
        parts.join('  ·  ').toUpperCase(),
        style: EdeType.label.copyWith(color: context.tokens.inkFaint),
      );
}

// ================================================================== CARDS ==

class EdeCard extends StatelessWidget {
  const EdeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EdeSpace.lg),
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint ?? context.colors.surface,
      borderRadius: BorderRadius.circular(EdeRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EdeRadius.card),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EdeRadius.card),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================ AUDIO / WHY ==

/// Icons are never unlabelled where meaning is not obvious (see UX principle
/// "never make beginners guess icons").
class AudioButton extends StatelessWidget {
  const AudioButton({super.key, required this.onPlay, this.slow = false, this.playing = false});

  final VoidCallback onPlay;
  final bool slow;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: slow ? 'ฟังแบบช้า' : 'ฟัง',
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        child: Container(
          height: kMinTap,
          padding: const EdgeInsets.symmetric(horizontal: EdeSpace.lg),
          decoration: BoxDecoration(
            color: context.tokens.primarySurface,
            borderRadius: BorderRadius.circular(EdeRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  size: 20, color: context.colors.primary),
              const SizedBox(width: 6),
              Text(slow ? 'ช้า' : 'ฟัง',
                  style: EdeType.button.copyWith(fontSize: 15, color: context.colors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The most important control in the product. Deliberately quiet — it must be
/// available without demanding attention, because a beginner should be able to
/// ignore it and an unsure learner should always find it in the same place.
class WhyButton extends StatelessWidget {
  const WhyButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'ทำไมถึงใช้แบบนี้',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        child: Container(
          height: kMinTap,
          padding: const EdgeInsets.symmetric(horizontal: EdeSpace.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EdeRadius.pill),
            border: Border.all(color: context.colors.primary.withValues(alpha: .45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline_rounded, size: 18, color: context.colors.primary),
              const SizedBox(width: 6),
              Text('ทำไม?',
                  style: EdeType.button.copyWith(fontSize: 15, color: context.colors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================= STATES ==

/// An empty screen is an invitation to act, so it always carries an action.
class EdeEmptyState extends StatelessWidget {
  const EdeEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdeSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AzulejoTile(size: 64, progress: 0),
            const SizedBox(height: EdeSpace.xl),
            Text(title, style: EdeType.thaiTitle.copyWith(color: context.colors.onSurface)),
            const SizedBox(height: EdeSpace.sm),
            Text(body,
                textAlign: TextAlign.center,
                style: EdeType.thaiBody.copyWith(color: context.tokens.inkSoft)),
            if (actionLabel != null) ...[
              const SizedBox(height: EdeSpace.xl),
              EdePrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Errors explain what happened and how to fix it, and never apologise.
/// When the learner's work is safe, they are told so explicitly.
class EdeErrorState extends StatelessWidget {
  const EdeErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.workIsSafe = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool workIsSafe;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdeSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.tokens.inkFaint),
            const SizedBox(height: EdeSpace.lg),
            Text(message,
                textAlign: TextAlign.center,
                style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
            if (workIsSafe) ...[
              const SizedBox(height: EdeSpace.sm),
              Text('คำตอบของคุณยังไม่หาย',
                  style: EdeType.thaiBodySmall.copyWith(color: context.tokens.correct)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: EdeSpace.xl),
              EdePrimaryButton(label: 'ลองอีกครั้ง', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class EdeSkeleton extends StatefulWidget {
  const EdeSkeleton({super.key, this.height = 20, this.width = double.infinity});

  final double height;
  final double width;

  @override
  State<EdeSkeleton> createState() => _EdeSkeletonState();
}

class _EdeSkeletonState extends State<EdeSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the platform reduced-motion setting.
    if (MediaQuery.of(context).disableAnimations) {
      return _bar(context, .5);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => _bar(context, .35 + _c.value * .35),
    );
  }

  Widget _bar(BuildContext context, double a) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant.withValues(alpha: a),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}


// ================================================= SELECTION CONTROLS ======

/// A selectable row. Selection is carried by border + fill + a check icon, not
/// by colour alone, so it survives greyscale and colour-blind rendering.
class EdeChoiceTile extends StatelessWidget {
  const EdeChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTap + 8),
          padding: const EdgeInsets.symmetric(
              horizontal: EdeSpace.lg, vertical: EdeSpace.md),
          decoration: BoxDecoration(
            color: selected ? context.tokens.primarySurface : context.colors.surface,
            borderRadius: BorderRadius.circular(EdeRadius.control),
            border: Border.all(
              color: selected
                  ? context.colors.primary
                  : context.colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: EdeType.thaiBody.copyWith(
                          color: context.colors.onSurface,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        )),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(sublabel!,
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.tokens.inkSoft)),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    size: 22, color: context.colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class EdePill extends StatelessWidget {
  const EdePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EdeRadius.pill),
        child: Container(
          height: kMinTap,
          padding: const EdgeInsets.symmetric(horizontal: EdeSpace.lg),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? context.colors.primary : context.colors.surface,
            borderRadius: BorderRadius.circular(EdeRadius.pill),
            border: Border.all(
                color: selected
                    ? context.colors.primary
                    : context.colors.outlineVariant),
          ),
          child: Text(label,
              style: EdeType.button.copyWith(
                fontSize: 15,
                color: selected ? context.colors.onPrimary : context.colors.onSurface,
              )),
        ),
      ),
    );
  }
}

/// A small caption used wherever the app is running on development stubs.
/// It exists so a stub is never mistaken for the real thing.
class EdeDevBadge extends StatelessWidget {
  const EdeDevBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EdeSpace.md, vertical: EdeSpace.sm),
      decoration: BoxDecoration(
        color: context.tokens.retrySurface,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        border: Border.all(color: context.tokens.retry.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.construction_rounded, size: 16, color: context.tokens.retry),
          const SizedBox(width: EdeSpace.sm),
          Expanded(
            child: Text(text,
                style: EdeType.thaiBodySmall.copyWith(color: context.tokens.retry)),
          ),
        ],
      ),
    );
  }
}

/// Section label used inside the lesson player and deep grammar cards.
class EdeSectionLabel extends StatelessWidget {
  const EdeSectionLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: context.tokens.inkFaint),
          const SizedBox(width: 6),
        ],
        Expanded(child: GrammarLabel(parts: [text])),
      ],
    );
  }
}

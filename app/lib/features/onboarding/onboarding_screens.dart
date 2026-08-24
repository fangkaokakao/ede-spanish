import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// Onboarding is five short steps and no more. The learner must reach Spanish
/// within a couple of minutes, so nothing optional is asked before the first
/// lesson — no notification prompt, no account wall, no placement test for
/// someone who has never studied.
final onboardingDraftProvider =
    NotifierProvider<OnboardingDraft, LearnerPreferences>(OnboardingDraft.new);

class OnboardingDraft extends Notifier<LearnerPreferences> {
  @override
  LearnerPreferences build() => const LearnerPreferences();

  void setGoal(LearningGoal g) => state = state.copyWith(goal: g);
  void setStudiedBefore(bool v) => state = state.copyWith(hasStudiedBefore: v);
  void setMinutes(int m) => state = state.copyWith(dailyGoalMinutes: m);
  void setSelfRef(SelfReference s) => state = state.copyWith(selfReference: s);

  Future<void> finish(WidgetRef ref) async {
    final prefs = state.copyWith(onboardingComplete: true);
    await ref.read(learnerRepositoryProvider).savePreferences(prefs);
    ref.invalidate(preferencesProvider);
    ref.invalidate(dailyPlanProvider);
  }
}

/// Shared chrome: a step counter, a title, a body, and exactly one primary
/// action pinned within thumb reach.
class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.titleTh,
    this.subtitleTh,
    required this.child,
    required this.primaryLabel,
    this.onPrimary,
    this.onSkip,
    this.skipLabel,
  });

  final int step;
  final String titleTh;
  final String? subtitleTh;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSkip;
  final String? skipLabel;

  static const total = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  EdeSpace.gutter, EdeSpace.lg, EdeSpace.gutter, 0),
              child: Row(
                children: [
                  for (var i = 1; i <= total; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i == total ? 0 : 4),
                        decoration: BoxDecoration(
                          color: i <= step
                              ? context.colors.primary
                              : context.colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    EdeSpace.gutter, EdeSpace.xxl, EdeSpace.gutter, EdeSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleTh,
                        style: EdeType.thaiHeadline
                            .copyWith(color: context.colors.onSurface)),
                    if (subtitleTh != null) ...[
                      const SizedBox(height: EdeSpace.sm),
                      Text(subtitleTh!,
                          style: EdeType.thaiBody
                              .copyWith(color: context.tokens.inkSoft)),
                    ],
                    const SizedBox(height: EdeSpace.xl),
                    child,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  EdeSpace.gutter, 0, EdeSpace.gutter, EdeSpace.lg),
              child: Column(
                children: [
                  EdePrimaryButton(label: primaryLabel, onPressed: onPrimary),
                  if (onSkip != null)
                    Padding(
                      padding: const EdgeInsets.only(top: EdeSpace.xs),
                      child: EdeTextButton(
                          label: skipLabel ?? 'ข้ามไปก่อน', onPressed: onSkip),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String label;
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EdeSpace.md),
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EdeRadius.control),
          child: Container(
            width: double.infinity,
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
                    children: [
                      Text(label,
                          style: EdeType.thaiBody
                              .copyWith(color: context.colors.onSurface)),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(note!,
                            style: EdeType.thaiBodySmall
                                .copyWith(color: context.tokens.inkFaint)),
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
      ),
    );
  }
}

// ------------------------------------------------------------------ screens --

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EdeSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const AzulejoTile(size: 76, progress: 1, highlight: true),
              const SizedBox(height: EdeSpace.xl),
              // Spanish leads, because the product is the language.
              Text('Español de España',
                  style: EdeType.spanishDisplay
                      .copyWith(color: context.colors.onSurface)),
              const SizedBox(height: EdeSpace.md),
              Text('เรียนภาษาสเปนแบบที่คนสเปนใช้จริง อธิบายเป็นภาษาไทยตั้งแต่คำแรก',
                  style: EdeType.thaiBody.copyWith(color: context.tokens.inkSoft)),
              const SizedBox(height: EdeSpace.lg),
              Container(
                padding: const EdgeInsets.all(EdeSpace.lg),
                decoration: BoxDecoration(
                  color: context.tokens.primarySurface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 18, color: context.colors.primary),
                    const SizedBox(width: EdeSpace.sm),
                    Expanded(
                      child: Text(
                          'คอร์สนี้สอนภาษาสเปนของประเทศสเปน (ใช้ vosotros และออกเสียงแบบสเปน)',
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.colors.primary)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              EdePrimaryButton(
                label: 'เริ่มต้น',
                onPressed: () => context.go('/onboarding/goal'),
              ),
              const SizedBox(height: EdeSpace.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return _Step(
      step: 1,
      titleTh: 'คุณเรียนภาษาสเปนไปเพื่ออะไร',
      subtitleTh: 'เราจะเลือกบทเรียนและสถานการณ์ให้ตรงกับเป้าหมายของคุณ',
      primaryLabel: 'ต่อไป',
      onPrimary: draft.goal == null
          ? null
          : () => context.go('/onboarding/experience'),
      child: Column(
        children: [
          for (final g in LearningGoal.values)
            _Choice(
              label: g.labelTh,
              selected: draft.goal == g,
              onTap: () => ref.read(onboardingDraftProvider.notifier).setGoal(g),
            ),
        ],
      ),
    );
  }
}

class ExperienceScreen extends ConsumerWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return _Step(
      step: 2,
      titleTh: 'คุณเคยเรียนภาษาสเปนมาก่อนไหม',
      primaryLabel: 'ต่อไป',
      onPrimary: () => context.go('/onboarding/daily-goal'),
      child: Column(
        children: [
          _Choice(
            label: 'ไม่เคยเรียนภาษาสเปนเลย',
            note: 'เริ่มจาก Pre-A1 ตั้งแต่เสียงและคำแรก ไม่ต้องสอบวัดระดับ',
            selected: !draft.hasStudiedBefore,
            onTap: () =>
                ref.read(onboardingDraftProvider.notifier).setStudiedBefore(false),
          ),
          _Choice(
            label: 'เคยเรียนมาบ้าง',
            note: 'จะมีแบบทดสอบวัดระดับสั้น ๆ (ยังไม่เปิดใช้ในเวอร์ชันนี้)',
            selected: draft.hasStudiedBefore,
            onTap: () =>
                ref.read(onboardingDraftProvider.notifier).setStudiedBefore(true),
          ),
          if (draft.hasStudiedBefore)
            Padding(
              padding: const EdgeInsets.only(top: EdeSpace.sm),
              child: Container(
                padding: const EdgeInsets.all(EdeSpace.md),
                decoration: BoxDecoration(
                  color: context.tokens.accentSurface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                ),
                child: Text(
                    'แบบทดสอบวัดระดับยังไม่เปิดใช้งาน ตอนนี้จะเริ่มที่ Pre-A1 ก่อน '
                    'ซึ่งข้ามบทที่ง่ายเกินไปได้',
                    style: EdeType.thaiBodySmall
                        .copyWith(color: context.tokens.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

class DailyGoalScreen extends ConsumerWidget {
  const DailyGoalScreen({super.key});

  static const _options = [5, 10, 15, 20, 30, 45];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    return _Step(
      step: 3,
      titleTh: 'วันละกี่นาที',
      subtitleTh: 'เลือกเวลาที่ทำได้จริงทุกวัน ดีกว่าเลือกเยอะแล้วไม่ได้ทำ',
      primaryLabel: 'ต่อไป',
      onPrimary: () => context.go('/onboarding/self-reference'),
      child: Column(
        children: [
          for (final m in _options)
            _Choice(
              label: '$m นาที',
              note: switch (m) {
                5 => 'ทบทวนสั้น ๆ',
                15 => 'พอสำหรับหนึ่งบทเรียน',
                45 => 'เข้มข้น',
                _ => null,
              },
              selected: draft.dailyGoalMinutes == m,
              onTap: () => ref.read(onboardingDraftProvider.notifier).setMinutes(m),
            ),
        ],
      ),
    );
  }
}

/// The self-reference step. It affects only sentences that genuinely describe
/// the learner, and it is never inferred from anything — which is why it is an
/// explicit, skippable question rather than a guess.
class SelfReferenceScreen extends ConsumerWidget {
  const SelfReferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);

    Future<void> done() async {
      await notifier.finish(ref);
      if (context.mounted) context.go('/home');
    }

    return _Step(
      step: 4,
      titleTh: 'เวลาพูดถึงตัวเอง อยากเห็นรูปไหน',
      subtitleTh:
          'ในภาษาสเปน คำคุณศัพท์ที่อธิบายตัวผู้พูดจะเปลี่ยนรูป เช่น Estoy cansado / Estoy cansada '
          'ตัวเลือกนี้ไม่กระทบเพศของคำนามอื่น และเปลี่ยนได้ทีหลัง',
      primaryLabel: 'เริ่มเรียน',
      onPrimary: done,
      onSkip: done,
      skipLabel: 'ยังไม่เลือก (แสดงทั้งสองรูป)',
      child: Column(
        children: [
          for (final s in SelfReference.values)
            _Choice(
              label: s.labelTh,
              selected: draft.selfReference == s,
              onTap: () => notifier.setSelfRef(s),
            ),
          const SizedBox(height: EdeSpace.md),
          Container(
            padding: const EdgeInsets.all(EdeSpace.lg),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(EdeRadius.control),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GrammarLabel(parts: ['ตัวอย่าง']),
                const SizedBox(height: EdeSpace.sm),
                Text('La casa es bonita.',
                    style: EdeType.spanishInline
                        .copyWith(color: context.colors.onSurface)),
                const SizedBox(height: EdeSpace.xs),
                Text('ประโยคนี้ไม่เปลี่ยน ไม่ว่าผู้พูดเป็นใคร เพราะ bonita ตามคำว่า casa',
                    style: EdeType.thaiBodySmall
                        .copyWith(color: context.tokens.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

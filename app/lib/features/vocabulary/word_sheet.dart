import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// Tap any Spanish word to look it up, without leaving the lesson.
Future<void> showWordSheet(
  BuildContext context, {
  String? word,
  VocabSense? sense,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WordSheet(word: word, sense: sense),
  );
}

class WordSheet extends ConsumerWidget {
  const WordSheet({super.key, this.word, this.sense});

  final String? word;
  final VocabSense? sense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sense != null) return _Content(sense: sense!);

    // Looked up by surface form. The pack indexes senses by id, so a tapped
    // inflected form may legitimately have no entry — an honest empty state,
    // not a guess.
    final ids = const [
      '88888888-8888-4888-8888-888888888801',
      '88888888-8888-4888-8888-888888888802',
      '88888888-8888-4888-8888-888888888803',
    ];
    final async = ref.watch(sensesProvider(ids));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(EdeSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EdeSkeleton(height: 28, width: 140),
            SizedBox(height: EdeSpace.md),
            EdeSkeleton(height: 14),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(EdeSpace.gutter),
        child: EdeErrorState(message: 'เปิดคำศัพท์ไม่ได้', onRetry: () {}),
      ),
      data: (senses) {
        final w = (word ?? '').toLowerCase();
        final hit = senses.where((s) {
          final lemma = s.lemma.toLowerCase();
          return lemma == w ||
              lemma.startsWith(w.length > 4 ? w.substring(0, 4) : w) ||
              (w.startsWith('llam') && lemma.startsWith('llam'));
        }).toList();

        if (hit.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(EdeSpace.gutter),
            child: SizedBox(
              height: 260,
              child: EdeEmptyState(
                title: word == null ? 'ไม่พบคำนี้' : '“$word” ยังไม่มีในคลังคำศัพท์',
                body: 'คำนี้ยังไม่ได้ถูกเพิ่มเข้าคลังคำศัพท์ของบทนี้ '
                    'เราจะไม่แสดงความหมายที่ระบบเดาเอง',
              ),
            ),
          );
        }
        return _Content(sense: hit.first);
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.sense});
  final VocabSense sense;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            EdeSpace.gutter, 0, EdeSpace.gutter, EdeSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sense.articleHint,
                style: EdeType.spanishDisplay
                    .copyWith(color: context.colors.onSurface)),
            const SizedBox(height: EdeSpace.xs),
            Text(sense.meaningTh,
                style: EdeType.thaiBody.copyWith(color: t.inkSoft)),
            const SizedBox(height: EdeSpace.md),
            GrammarLabel(parts: [
              sense.pos,
              if (sense.gender == 'm') 'masculino',
              if (sense.gender == 'f') 'femenino',
              if (sense.pluralForm != null) 'pl. ${sense.pluralForm}',
            ]),

            // Two transcriptions, labelled, because they are different claims.
            if (sense.ipaPhonemic != null) ...[
              const SizedBox(height: EdeSpace.lg),
              Row(
                children: [
                  _Ipa(label: 'หน่วยเสียง', value: sense.ipaPhonemic!),
                  if (sense.ipaPhonetic != null) ...[
                    const SizedBox(width: EdeSpace.sm),
                    _Ipa(label: 'เสียงจริง', value: sense.ipaPhonetic!),
                  ],
                ],
              ),
            ],

            if (sense.spainNote != null) ...[
              const SizedBox(height: EdeSpace.lg),
              Container(
                padding: const EdgeInsets.all(EdeSpace.lg),
                decoration: BoxDecoration(
                  color: t.primarySurface,
                  borderRadius: BorderRadius.circular(EdeRadius.control),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 16, color: context.colors.primary),
                    const SizedBox(width: EdeSpace.sm),
                    Expanded(
                      child: Text(sense.spainNote!,
                          style: EdeType.thaiBodySmall
                              .copyWith(color: context.colors.onSurface)),
                    ),
                  ],
                ),
              ),
            ],

            if (sense.examples.isNotEmpty) ...[
              const SizedBox(height: EdeSpace.xl),
              const GrammarLabel(parts: ['ตัวอย่าง']),
              const SizedBox(height: EdeSpace.sm),
              for (final e in sense.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: EdeSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.es,
                          style: EdeType.spanishInline
                              .copyWith(color: context.colors.onSurface)),
                      Text(e.th,
                          style: EdeType.thaiBodySmall.copyWith(color: t.inkSoft)),
                    ],
                  ),
                ),
            ],

            if (sense.collocations.isNotEmpty) ...[
              const SizedBox(height: EdeSpace.lg),
              const GrammarLabel(parts: ['ใช้บ่อยกับ']),
              const SizedBox(height: EdeSpace.sm),
              for (final c in sense.collocations)
                Padding(
                  padding: const EdgeInsets.only(bottom: EdeSpace.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(c.phrase,
                            style: EdeType.spanishInline
                                .copyWith(color: context.colors.onSurface)),
                      ),
                      const SizedBox(width: EdeSpace.md),
                      Expanded(
                        child: Text(c.th,
                            style: EdeType.thaiBodySmall
                                .copyWith(color: t.inkSoft)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ipa extends StatelessWidget {
  const _Ipa({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EdeSpace.md, vertical: EdeSpace.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(EdeRadius.control),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: EdeType.thaiBodySmall
                  .copyWith(fontSize: 11, color: context.tokens.inkFaint)),
          Text(value,
              style: EdeType.numeric.copyWith(color: context.colors.onSurface)),
        ],
      ),
    );
  }
}

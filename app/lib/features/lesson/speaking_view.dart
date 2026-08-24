import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/speech_repository_impl.dart';
import '../../design_system/components.dart';
import '../../design_system/learning_widgets.dart';
import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../domain/entities.dart';

/// Speaking practice: model → record → compare → retry.
///
/// There is no score. No percentage, no "87%", no verdict, no detected error.
/// No ASR and no pronunciation-assessment provider is connected, so any number
/// here would be fabricated. Instead the learner gets the thing that actually
/// helps at this level: the native model at two speeds, their own recording
/// beside it, and unlimited retries. The absence of automatic assessment is
/// stated plainly rather than hidden.
class SpeakingView extends ConsumerStatefulWidget {
  const SpeakingView({
    super.key,
    required this.exercise,
    required this.sessionId,
    this.onDone,
  });

  final Exercise exercise;
  final String sessionId;
  final VoidCallback? onDone;

  @override
  ConsumerState<SpeakingView> createState() => _SpeakingViewState();
}

class _SpeakingViewState extends ConsumerState<SpeakingView> {
  bool _recording = false;
  bool _busy = false;
  String? _recordingPath;
  String? _error;
  bool _submitted = false;
  DateTime? _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final repo = ref.read(speechRepositoryProvider);
    if (_busy) return;

    if (_recording) {
      setState(() => _busy = true);
      _ticker?.cancel();
      final path = await repo.stopRecording();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _busy = false;
        _recordingPath = path;
      });
      return;
    }

    setState(() => _busy = true);
    final granted = await repo.hasPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'ต้องอนุญาตให้ใช้ไมโครโฟนก่อน จึงจะบันทึกเสียงได้';
      });
      return;
    }

    try {
      final path = await DeviceSpeechRepository.newRecordingPath();
      await repo.startRecording(path);
      if (!mounted) return;
      _startedAt = DateTime.now();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
      setState(() {
        _recording = true;
        _busy = false;
        _error = null;
        _recordingPath = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'เริ่มบันทึกเสียงไม่ได้ ลองอีกครั้ง';
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(speechRepositoryProvider).submitSpeech(
            submissionId: _submissionId(),
            exerciseId: widget.exercise.id,
            sessionId: widget.sessionId,
            audioPath: _recordingPath,
            durationMs: _elapsed.inMilliseconds,
          );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _busy = false;
      });
      ref.invalidate(satisfiedProvider);
      widget.onDone?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'บันทึกไม่สำเร็จ ลองอีกครั้ง — เสียงที่อัดไว้ยังอยู่';
      });
    }
  }

  String _submissionId() {
    final seed = '${widget.exercise.id}-speech'
        .hashCode
        .toUnsigned(32)
        .toRadixString(16)
        .padLeft(8, '0');
    return '$seed-0000-4000-8000-'
        '${widget.exercise.id.substring(widget.exercise.id.length - 12)}';
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final t = context.tokens;
    final audio = ref.read(modelAudioProvider);

    return EdeCard(
      padding: const EdgeInsets.all(EdeSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GrammarLabel(parts: ['ฝึกพูด']),
          const SizedBox(height: EdeSpace.md),
          Text(ex.promptTh,
              style: EdeType.thaiBody.copyWith(color: context.colors.onSurface)),
          const SizedBox(height: EdeSpace.lg),

          // Target sentence, prominent. The name slot is shown as a blank
          // because the learner's own name is content, not a target.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EdeSpace.lg),
            decoration: BoxDecoration(
              color: t.primarySurface,
              borderRadius: BorderRadius.circular(EdeRadius.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.displayEs ?? ex.scoredFrame ?? '',
                    style: EdeType.spanishDisplay
                        .copyWith(color: context.colors.onSurface)),
                if (ex.focusTh != null) ...[
                  const SizedBox(height: EdeSpace.sm),
                  Text(ex.focusTh!,
                      style: EdeType.thaiBodySmall.copyWith(color: t.inkSoft)),
                ],
              ],
            ),
          ),
          const SizedBox(height: EdeSpace.lg),
          AudioControls(
            onNormal: () => audio.play('pre-a1/u1/llamo-word.m4a'),
            onSlow: () => audio.play('pre-a1/u1/llamo-word-slow.m4a', speed: 0.7),
          ),
          const SizedBox(height: EdeSpace.xl),

          Center(child: _MicButton(
            recording: _recording,
            busy: _busy,
            onTap: _toggleRecord,
          )),
          const SizedBox(height: EdeSpace.md),
          Center(
            child: Text(
              _recording
                  ? 'กำลังฟัง… ${_elapsed.inSeconds}s'
                  : _recordingPath != null
                      ? 'อัดเสียงแล้ว'
                      : 'กดเพื่อเริ่มพูด',
              style: EdeType.thaiBodySmall.copyWith(color: t.inkFaint),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: EdeSpace.md),
            Text(_error!,
                style: EdeType.thaiBodySmall.copyWith(color: t.retry)),
          ],

          if (_recordingPath != null && !_recording) ...[
            const SizedBox(height: EdeSpace.lg),
            Wrap(
              spacing: EdeSpace.sm,
              runSpacing: EdeSpace.sm,
              children: [
                EdeTextButton(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'ฟังเสียงตัวเอง',
                  onPressed: () => ref
                      .read(speechRepositoryProvider)
                      .playback(_recordingPath!),
                ),
                EdeTextButton(
                  icon: Icons.compare_arrows_rounded,
                  label: 'ฟังเสียงต้นแบบ',
                  onPressed: () => audio.play('pre-a1/u1/llamo-word.m4a'),
                ),
                EdeTextButton(
                  icon: Icons.refresh_rounded,
                  label: 'อัดใหม่',
                  onPressed: () => setState(() {
                    _recordingPath = null;
                    _elapsed = Duration.zero;
                  }),
                ),
              ],
            ),

            // The honesty notice. Stated before the learner can wonder why
            // there is no score.
            const SizedBox(height: EdeSpace.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(EdeSpace.lg),
              decoration: BoxDecoration(
                color: t.accentSurface,
                borderRadius: BorderRadius.circular(EdeRadius.control),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: t.accent),
                  const SizedBox(width: EdeSpace.sm),
                  Expanded(
                    child: Text(
                      'ระบบตรวจการออกเสียงอัตโนมัติยังไม่เปิดใช้งาน '
                      'แอปจะไม่ให้คะแนนที่เดาขึ้นมาเอง — ตอนนี้ลองฟังเสียงต้นแบบ '
                      'สลับกับเสียงตัวเอง แล้วสังเกตเสียง ll ว่าใกล้ ย หรือยัง',
                      style: EdeType.thaiBodySmall
                          .copyWith(color: context.colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: EdeSpace.lg),
            if (_submitted)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 20, color: t.correct),
                  const SizedBox(width: EdeSpace.sm),
                  Text('ทำแบบฝึกหัดพูดแล้ว',
                      style: EdeType.thaiBody.copyWith(color: t.correct)),
                ],
              )
            else
              EdePrimaryButton(
                label: 'ส่งการฝึกพูดนี้',
                loading: _busy,
                onPressed: _submit,
              ),
          ],
        ],
      ),
    );
  }
}

/// One large, obvious target. Nothing else competes with it while recording.
class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.recording,
    required this.busy,
    required this.onTap,
  });

  final bool recording, busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: recording ? 'หยุดบันทึกเสียง' : 'เริ่มบันทึกเสียง',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedScale(
          scale: recording && !reduce ? 1.06 : 1.0,
          duration: EdeMotion.standard,
          curve: EdeMotion.curve,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? context.tokens.retry
                  : context.colors.primary,
              boxShadow: recording
                  ? [
                      BoxShadow(
                        color: context.tokens.retry.withValues(alpha: .25),
                        blurRadius: 24,
                        spreadRadius: 6,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

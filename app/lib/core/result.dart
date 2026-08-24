/// A tiny Result type so the data layer never throws across a layer boundary
/// and every call site is forced to consider the failure path.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure f) err,
  }) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Failures carry a Thai message because that is what the learner reads.
/// The UI must never string-match on an English server message.
class Failure {
  const Failure({
    required this.code,
    required this.messageTh,
    this.retryable = true,
    this.workIsSafe = false,
    this.correlationId,
  });

  final String code;
  final String messageTh;
  final bool retryable;

  /// Set when the learner submitted something and it was persisted locally.
  /// Drives the "คำตอบของคุณยังไม่หาย" line in EdeErrorState.
  final bool workIsSafe;
  final String? correlationId;

  static const offline = Failure(
    code: 'offline',
    messageTh: 'ตอนนี้ไม่ได้เชื่อมต่ออินเทอร์เน็ต บทเรียนที่ดาวน์โหลดไว้ยังใช้ได้',
    workIsSafe: true,
  );

  static const contentLoad = Failure(
    code: 'content_load',
    messageTh: 'โหลดบทเรียนไม่ได้ กรุณาลองอีกครั้ง',
  );

  static const aiUnavailable = Failure(
    code: 'ai_unavailable',
    messageTh: 'ครู AI ตอบไม่ได้ตอนนี้ ลองใหม่อีกครั้งได้เลย',
    workIsSafe: true,
  );

  static const asrLowConfidence = Failure(
    code: 'asr_low_confidence',
    messageTh: 'ระบบไม่แน่ใจว่าได้ยินถูกหรือไม่ ลองพูดอีกครั้งในที่เงียบกว่านี้',
    workIsSafe: true,
  );
}

import 'dart:async';

abstract class TaskEvent {}

// ดึงรายการงานตามวันที่ และ Merge กับคิวในเครื่อง
class SyncTasksWithQueue extends TaskEvent {
  final DateTime selectedDate;
  SyncTasksWithQueue(this.selectedDate);
}

// ดึงรายละเอียดคำตอบรายชิ้น (เพื่อเอามาใส่ในฟอร์ม)
class GetTaskResponseDetails extends TaskEvent {
  final String taskId;
  // null = prefill every answer (single-submit: the form edits that one
  // row). A set = multi-submit: the form starts a NEW row, so only these
  // carry-forward fields are copied from the previous answer -- an empty
  // set means start blank.
  final Set<String>? onlyFields;
  GetTaskResponseDetails(this.taskId, {this.onlyFields});
}

// What actually happened to a SubmitTaskAction -- so the form can show
// สำเร็จ / ไม่สำเร็จ for what REALLY happened instead of closing the moment
// the answer was handed over.
enum SubmitOutcome {
  // The server accepted it.
  sent,
  // Not sent, but kept in the local queue -- TriggerPendingQueueSync sends
  // it later. Covers offline AND a server error.
  savedOffline,
  // Saved as a draft on this device (never sent by design).
  draftSaved,
  // Neither sent nor saved locally -- the one case where the answer is lost
  // unless the farmer tries again.
  failed,
}

class SubmitResult {
  final SubmitOutcome outcome;
  // The server's own reason when it answered with an error (ServiceProvider
  // throws the body's "error" text as a String); null for a network failure.
  final String? serverError;
  const SubmitResult(this.outcome, {this.serverError});
}

// ส่งงานหรือบันทึกร่าง
class SubmitTaskAction extends TaskEvent {
  final String taskId;
  final String handler;
  final Map<String, dynamic> payload;
  final bool isDraft;
  final bool isEdit;
  // Completed exactly once with what happened. Optional: other callers can
  // still fire and forget.
  final Completer<SubmitResult>? result;

  SubmitTaskAction(this.taskId, this.handler, this.payload, {this.isDraft = false, this.isEdit = false, this.result});
}

class TriggerPendingQueueSync extends TaskEvent {
  final DateTime selectedDate;
  TriggerPendingQueueSync(this.selectedDate);
}
// พยายามส่งงานที่ค้างในคิว (PENDING) ขึ้น Server
abstract class TaskEvent {}

// ดึงรายการงานตามวันที่ และ Merge กับคิวในเครื่อง
class SyncTasksWithQueue extends TaskEvent {
  final DateTime selectedDate;
  SyncTasksWithQueue(this.selectedDate);
}

// ดึงรายละเอียดคำตอบรายชิ้น (เพื่อเอามาใส่ในฟอร์ม)
class GetTaskResponseDetails extends TaskEvent {
  final String taskId;
  GetTaskResponseDetails(this.taskId);
}

// ส่งงานหรือบันทึกร่าง
class SubmitTaskAction extends TaskEvent {
  final String taskId;
  final String handler;
  final Map<String, dynamic> payload;
  final bool isDraft;
  final bool isEdit; 

  SubmitTaskAction(this.taskId, this.handler, this.payload, {this.isDraft = false, this.isEdit = false});
}

class TriggerPendingQueueSync extends TaskEvent {
  final DateTime selectedDate;
  TriggerPendingQueueSync(this.selectedDate);
}
// พยายามส่งงานที่ค้างในคิว (PENDING) ขึ้น Server
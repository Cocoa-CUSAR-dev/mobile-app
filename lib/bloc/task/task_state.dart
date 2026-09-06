// lib/bloc/task/task_state.dart
import 'package:cocoa_supply/models/task_item_model.dart';

class TaskState {
  final List<TaskItem> tasks;
  final bool isLoading;
  final bool isLoadingDetails;
  final Map<String, dynamic>? currentTaskResponse; // ข้อมูลคำตอบที่ Fetch มาได้

  // APP-5: queued submissions that TriggerPendingQueueSync found already had
  // a server-side response by the time this device tried to send them
  // (e.g. hub staff submitted the same task while this device was
  // offline) -- these are held back rather than blindly overwritten, and
  // surfaced here instead of just vanishing. Each entry is the original
  // queue item (task_id/answer/timestamp/etc.), unmodified, so a screen
  // can show "N items need review" and let the farmer decide, once a UI
  // is wired to this field.
  final List<Map<String, dynamic>> pendingConflicts;

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.currentTaskResponse,
    this.pendingConflicts = const [],
  });

  TaskState copyWith({
    List<TaskItem>? tasks,
    bool? isLoading,
    bool? isLoadingDetails,
    Map<String, dynamic>? currentTaskResponse,
    List<Map<String, dynamic>>? pendingConflicts,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      currentTaskResponse: currentTaskResponse, // ยอมให้ส่ง null เพื่อล้างค่า
      pendingConflicts: pendingConflicts ?? this.pendingConflicts,
    );
  }
}
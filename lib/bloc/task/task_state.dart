// lib/bloc/task/task_state.dart
import 'package:cocoa_supply/models/task_item_model.dart';

class TaskState {
  final List<TaskItem> tasks;
  final bool isLoading;
  final bool isLoadingDetails;
  final Map<String, dynamic>? currentTaskResponse; // ข้อมูลคำตอบที่ Fetch มาได้

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.currentTaskResponse,
  });

  TaskState copyWith({
    List<TaskItem>? tasks,
    bool? isLoading,
    bool? isLoadingDetails,
    Map<String, dynamic>? currentTaskResponse,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      currentTaskResponse: currentTaskResponse, // ยอมให้ส่ง null เพื่อล้างค่า
    );
  }
}
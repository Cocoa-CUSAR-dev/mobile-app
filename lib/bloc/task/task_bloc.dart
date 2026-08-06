// lib/bloc/task/task_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  // คิวในเครื่อง (SharedPreferences)
  final ServiceProvider<Map<String, dynamic>> _queueService = ServiceProvider(
    storageKey: 'pending_task_queue',
    endpoint: '/tasks',
    isRealApi: false,
  );

  TaskBloc({TaskService? taskService})
    : _taskService = taskService ?? TaskService(),
      super(TaskState()) {
    // 1. Sync รายการงาน
    on<SyncTasksWithQueue>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        final remoteTasks = await _taskService.getTasksByDate(
          event.selectedDate,
        );

        final List<Map<String, dynamic>> pendingQueue = await _queueService
            .fetchData((json) => json);

        final updatedTasks = remoteTasks.map((task) {
          final draft = pendingQueue.firstWhere(
            (item) => item['task_id'] == task.taskId,
            orElse: () => {},
          );
          // หากในเครื่องมี Draft/Pending แต่ใน Server ยังไม่เสร็จ ให้แสดงข้อมูลในเครื่อง
          if (draft.isNotEmpty && task.status == 'NOT_STARTED') {
            return task.copyWithPending(draft['answer']);
          }
          return task;
        }).toList();
        emit(state.copyWith(tasks: updatedTasks, isLoading: false));
      } catch (e) {
        print(e);
        emit(state.copyWith(isLoading: false));
      }
    });

    // 2. ดึงรายละเอียดคำตอบรายชิ้น
    on<GetTaskResponseDetails>((event, emit) async {
      emit(state.copyWith(isLoadingDetails: true, currentTaskResponse: null));
      try {
        // เช็กในคิวก่อน (ข้อมูลสดกว่า)
        final List<Map<String, dynamic>> pendingQueue = await _queueService
            .fetchData((json) => json);
        final draft = pendingQueue.firstWhere(
          (item) => item['task_id'] == event.taskId,
          orElse: () => {},
        );

        if (draft.isNotEmpty) {
          emit(
            state.copyWith(
              currentTaskResponse: draft['answer'],
              isLoadingDetails: false,
            ),
          );
        } else {
          // ถ้าไม่มีในคิว ค่อยไปถาม API
          final response = await _taskService.getTaskResponse(event.taskId);
          emit(
            state.copyWith(
              currentTaskResponse: response,
              isLoadingDetails: false,
            ),
          );
        }
      } catch (e) {
        emit(state.copyWith(isLoadingDetails: false));
      }
    });

    // 3. บันทึกงาน
    on<SubmitTaskAction>((event, emit) async {
      final queueItem = {
        'task_id': event.taskId,
        'handler': event.handler,
        'answer': event.payload,
        'is_edit': event.isEdit,
        'is_draft': event.isDraft,
        'status': event.isDraft
            ? 'DRAFT'
            : 'PENDING', // เก็บสถานะไว้เช็คตอน Trigger
        'timestamp': DateTime.now().toIso8601String(),
      };

      // ถ้าเป็น draft เอาเข้่าคิวเพื่อรอแก้พอ ยังไม่ส่ง
      if (event.isDraft){
        await _queueService.postData(queueItem);
        return;
      }
      // พยายามส่งขึ้น Server ทันที (Optimistic Update)
      try {
        // ถ้าเป็นงานที่มีอยู่แล้ว และจะ edit
        if (event.isEdit) {
          await _taskService.updateTask(event.taskId, event.payload);
        // ถ้าเป็นงานยังไม่เคยมีจะ submit
        } else {
          await _taskService.submitTask(event.taskId, event.payload);
        }
        // ถ้าสำเร็จ อาจจะลบออกจากคิวทันทีเพื่อไม่ให้ซ้ำซ้อน
        await _queueService.deleteData(event.taskId);
      } catch (e) {
        print(
          "Network failed, stay in queue as ${event.isDraft ? 'DRAFT' : 'PENDING'}",
        );
        // เอายัดเข้า queue รอ
        await _queueService.postData(queueItem);
      }

      // add(SyncTasksWithQueue(DateTime.now()));
    });
    // 4. Trigger Pending Queue เข้า database
    on<TriggerPendingQueueSync>((event, emit) async {
      final List<Map<String, dynamic>> pendingQueue = await _queueService
          .fetchData((json) => json);
      final List<Map<String, dynamic>> draftsToKeep = [];
      emit(state.copyWith(isLoading: true));
      for (var item in pendingQueue) {
        try {
          final String taskId = item['task_id'];
          final dynamic payload = item['answer'];
          final bool isDraft = item['is_draft'];
          final bool isEdit = item['is_edit'];

          if (isDraft){
            draftsToKeep.add(item);
            continue; //เป็นดราฟ ข้ามไปก่อน
          }

          if (isEdit) {
            // ถ้าเป็น Draft ให้ใช้ Update API
            await _taskService.updateTask(taskId, payload);
          } else {
            // ถ้าเป็น Pending/Submit ให้ใช้ Submit API
            await _taskService.submitTask(taskId, payload);
          }
        } catch (e) {
          print("Failed to sync task ${item['task_id']}: $e");
          // ถ้าตัวไหนพัง ให้ข้ามไปทำตัวถัดไปก่อน หรือหยุดรอตาม Business Logic
          continue;
        }
      }

      _queueService.deleteAll();

      for (var item in draftsToKeep){
        await _queueService.postData(item);
      }
      // เมื่อทำครบทุกตัว ให้ Sync ข้อมูลจาก Server อีกครั้งเพื่อให้ UI เป็นปัจจุบัน
      add(SyncTasksWithQueue(event.selectedDate));
    });
  }
}

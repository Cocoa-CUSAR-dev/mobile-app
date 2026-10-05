// lib/bloc/task/task_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:uuid/uuid.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  // คิวในเครื่อง (ผ่าน ServiceProvider -- secure storage หลัง APP-2)
  final ServiceProvider<Map<String, dynamic>> _queueService = ServiceProvider(
    storageKey: 'pending_task_queue',
    endpoint: '/tasks',
    isRealApi: false,
  );

  static const _uuid = Uuid();

  bool _isMultipleSubmit(String taskId) => state.tasks.any(
    (task) => task.taskId == taskId && task.isMultipleSubmit,
  );

  /// มีอะไรของงานนี้ค้างอยู่ในคิวในเครื่องไหม -- ร่าง หรือแถวที่ส่งแล้วรอ sync
  ///
  /// ใช้ตัดสินข้อเสนอ "ใช้ข้อมูลเดิม" (US2-5) ก่อนยิง network ใดๆ: ร่างต้องชนะเสมอ
  /// และแถวที่รอ sync แปลว่างานนี้มีคำตอบแล้ว (single-submit = โหมดแก้ไข,
  /// multi-submit = ไม่ใช่แถวแรก) ทั้งสองกรณีไม่เสนอ -- คิวเป็นของ TaskBloc
  /// จึงถามผ่านที่นี่แทนการให้ bloc อื่นเปิดอ่าน storage เอง
  Future<bool> hasQueuedItemFor(String taskId) async {
    final queue = await _queueService.fetchData((json) => json);
    return queue.any((item) => item['task_id'] == taskId);
  }

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
          if (draft.isNotEmpty &&
              (task.status == 'NOT_STARTED' || task.status == 'IN_PROGRESS')) {
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
        // The draft is the row being worked on, so it always wins. Other
        // queued rows are finished submissions waiting to sync: for a
        // single-submit task that row IS the answer being edited, but for a
        // multi-submit task it's a previous row, not this one.
        var draft = pendingQueue.firstWhere(
          (item) => item['task_id'] == event.taskId && item['is_draft'] == true,
          orElse: () => {},
        );
        if (draft.isEmpty && event.onlyFields == null) {
          draft = pendingQueue.firstWhere(
            (item) => item['task_id'] == event.taskId,
            orElse: () => {},
          );
        }

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
          final onlyFields = event.onlyFields;
          emit(
            state.copyWith(
              currentTaskResponse: response == null || onlyFields == null
                  ? response
                  : {
                      for (final key in onlyFields)
                        if (response[key] != null) key: response[key],
                    },
              isLoadingDetails: false,
            ),
          );
        }
      } catch (e) {
        emit(state.copyWith(isLoadingDetails: false));
      }
    });

    // 3. บันทึกงาน
    //
    // Every queue item gets its own queue_id. The queue used to be matched
    // on task_id alone, which is fine while a task has one answer, but a
    // multi-submit form (several grades for one harvest, several activities
    // on one plot) legitimately queues several rows for the same task
    // while offline -- those must all survive and all be sent.
    on<SubmitTaskAction>((event, emit) async {
      final queueItem = {
        'queue_id': _uuid.v4(),
        'task_id': event.taskId,
        'handler': event.handler,
        'answer': event.payload,
        'is_edit': event.isEdit,
        'is_draft': event.isDraft,
        'is_multiple_submit': _isMultipleSubmit(event.taskId),
        'status': event.isDraft
            ? 'DRAFT'
            : 'PENDING', // เก็บสถานะไว้เช็คตอน Trigger
        'timestamp': DateTime.now().toIso8601String(),
      };

      // A task has at most one draft -- the row being worked on right now.
      // Saving again replaces it (it used to append, and firstWhere then
      // kept showing the OLDEST copy), and submitting finalises it. Queued
      // PENDING rows are never touched here.
      Future<List<Map<String, dynamic>>> queueWithoutDraft() async {
        final queue = await _queueService.fetchData((json) => json);
        return queue
            .where(
              (item) =>
                  !(item['task_id'] == event.taskId && item['is_draft'] == true),
            )
            .toList();
      }

      // ถ้าเป็น draft เอาเข้่าคิวเพื่อรอแก้พอ ยังไม่ส่ง
      if (event.isDraft) {
        await _queueService.replaceLocal([
          ...await queueWithoutDraft(),
          queueItem,
        ]);
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
        await _queueService.replaceLocal(await queueWithoutDraft());
      } catch (e) {
        print("Network failed, stay in queue as PENDING");
        // เอายัดเข้า queue รอ -- appended, never replacing another row
        await _queueService.replaceLocal([
          ...await queueWithoutDraft(),
          queueItem,
        ]);
      }
    });
    // 4. Trigger Pending Queue เข้า database
    on<TriggerPendingQueueSync>((event, emit) async {
      final List<Map<String, dynamic>> pendingQueue = await _queueService
          .fetchData((json) => json);
      // Everything not successfully sent stays: drafts, conflicts, AND rows
      // whose send failed. Failed rows used to be dropped by the
      // deleteAll() below, losing the farmer's only copy on a flaky network.
      final List<Map<String, dynamic>> remaining = [];
      // APP-5: items that turned out to already have a server-side answer
      // by the time this device tried to send them -- held back instead of
      // blindly overwritten (see TaskState.pendingConflicts).
      final List<Map<String, dynamic>> conflicts = [];
      emit(state.copyWith(isLoading: true));
      for (final item in pendingQueue) {
        // Items queued before queue_id existed get one now.
        item['queue_id'] ??= _uuid.v4();
        try {
          final String taskId = item['task_id'];
          final dynamic payload = item['answer'];
          final bool isDraft = item['is_draft'] == true;
          final bool isEdit = item['is_edit'] == true;

          if (isDraft) {
            remaining.add(item);
            continue; //เป็นดราฟ ข้ามไปก่อน
          }

          if (isEdit) {
            // ถ้าเป็น Draft ให้ใช้ Update API
            await _taskService.updateTask(taskId, payload);
          } else {
            // APP-5: this device queued a fresh submission (not an edit)
            // while offline. If the server now already has an answer for
            // this task, someone/something else submitted it in the
            // meantime -- submitting on top would silently clobber that,
            // so check first instead of firing blind.
            //
            // Not for multi-submit forms: an existing answer there is
            // expected (often this device's own previous row from this
            // very loop), and a new row is added beside it, not over it.
            final bool isMultipleSubmit =
                item['is_multiple_submit'] == true || _isMultipleSubmit(taskId);
            if (!isMultipleSubmit) {
              final existing = await _taskService.getTaskResponse(taskId);
              if (existing != null) {
                conflicts.add(item);
                remaining.add(item);
                continue;
              }
            }
            await _taskService.submitTask(taskId, payload);
          }
        } catch (e) {
          print("Failed to sync task ${item['task_id']}: $e");
          remaining.add(item);
          continue;
        }
      }

      await _queueService.replaceLocal(remaining);
      emit(state.copyWith(pendingConflicts: conflicts));
      // เมื่อทำครบทุกตัว ให้ Sync ข้อมูลจาก Server อีกครั้งเพื่อให้ UI เป็นปัจจุบัน
      add(SyncTasksWithQueue(event.selectedDate));
    });
  }
}

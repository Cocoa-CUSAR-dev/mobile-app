// Unit tests for lib/bloc/task/task_bloc.dart.
//
// TaskBloc's local sync queue (_queueService) is hard-coded to
// isRealApi: false, so it always reads/writes through SharedPreferences
// regardless of the injected http.Client — only _taskService (the actual
// Go backend calls) needs the MockClient. That local queue also goes
// through ServiceProvider's mock branch, which has a real (non-fake-clock)
// 500ms `Future.delayed` network-simulation baked in, so every test that
// touches it needs `wait:` long enough for that delay to actually resolve.

import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

const _queueDelay = Duration(milliseconds: 700);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SyncTasksWithQueue', () {
    blocTest<TaskBloc, TaskState>(
      'merges remote tasks with an empty local queue (M-HOME-05 date navigation)',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'task_id': 't1', 'title': 'ตัดหญ้า', 'status': 'NOT_STARTED'},
          ], 200);
        });
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(SyncTasksWithQueue(DateTime(2026, 1, 11))),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<TaskState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.tasks.single.taskId, 'taskId', 't1'),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'a queued PENDING draft overrides a NOT_STARTED remote task',
      setUp: () {
        SharedPreferences.setMockInitialValues({
          'pending_task_queue': jsonEncode([
            {'task_id': 't1', 'answer': {'note': 'saved offline'}},
          ]),
        });
      },
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'task_id': 't1', 'title': 'ตัดหญ้า', 'status': 'NOT_STARTED'},
          ], 200);
        });
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(SyncTasksWithQueue(DateTime(2026, 1, 11))),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<TaskState>().having((s) => s.tasks.single.status, 'status', 'PENDING'),
      ],
    );
  });

  group('GetTaskResponseDetails', () {
    blocTest<TaskBloc, TaskState>(
      'falls back to the API when nothing is queued locally',
      build: () {
        final client = MockClient((request) async => jsonResponse({'note': 'from server'}, 200));
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(GetTaskResponseDetails('t1')),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoadingDetails, 'isLoadingDetails', isTrue),
        isA<TaskState>()
            .having((s) => s.isLoadingDetails, 'isLoadingDetails', isFalse)
            .having((s) => s.currentTaskResponse, 'currentTaskResponse', {'note': 'from server'}),
      ],
    );
  });

  group('SubmitTaskAction', () {
    blocTest<TaskBloc, TaskState>(
      'a draft submission is appended to the local pending queue and emits no state',
      build: () => TaskBloc(taskService: TaskService(client: MockClient((r) async => jsonResponse({}, 200)))),
      act: (bloc) => bloc.add(
        SubmitTaskAction('t1', 'activity', {'note': 'x'}, isDraft: true),
      ),
      wait: _queueDelay,
      expect: () => [],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        final queue = jsonDecode(prefs.getString('pending_task_queue')!) as List;
        expect(queue, hasLength(1));
        expect(queue.first['task_id'], 't1');
        expect(queue.first['status'], 'DRAFT');
      },
    );

    blocTest<TaskBloc, TaskState>(
      'a failed submit falls back to queuing the task as PENDING',
      build: () => TaskBloc(
        taskService: TaskService(client: MockClient((r) async => http.Response('error', 500))),
      ),
      act: (bloc) => bloc.add(SubmitTaskAction('t1', 'activity', {'note': 'x'})),
      wait: _queueDelay,
      expect: () => [],
      verify: (_) async {
        final prefs = await SharedPreferences.getInstance();
        final queue = jsonDecode(prefs.getString('pending_task_queue')!) as List;
        expect(queue.first['status'], 'PENDING');
      },
    );
  });
}

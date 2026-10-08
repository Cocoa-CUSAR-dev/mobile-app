// Unit tests for lib/bloc/task/task_bloc.dart.
//
// TaskBloc's local sync queue (_queueService) is hard-coded to
// isRealApi: false, so it always reads/writes through flutter_secure_storage
// (APP-2 -- was SharedPreferences) regardless of the injected http.Client —
// only _taskService (the actual Go backend calls) needs the MockClient. That
// local queue also goes through ServiceProvider's mock branch, which has a
// real (non-fake-clock) 500ms `Future.delayed` network-simulation baked in,
// so every test that touches it needs `wait:` long enough for that delay to
// actually resolve.

import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

const _secureStorage = FlutterSecureStorage();

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
        // The local sync queue lives in flutter_secure_storage (APP-2), not
        // SharedPreferences -- seed both.
        final queue = jsonEncode([
          {'task_id': 't1', 'answer': {'note': 'saved offline'}},
        ]);
        SharedPreferences.setMockInitialValues({'pending_task_queue': queue});
        FlutterSecureStorage.setMockInitialValues({'pending_task_queue': queue});
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

    // Multi-submit: the form starts a new row, so only carry-forward fields
    // come from the previous answer -- the rest must start blank.
    blocTest<TaskBloc, TaskState>(
      'with onlyFields, keeps just those fields of the previous answer',
      build: () {
        final client = MockClient((request) async =>
            jsonResponse({'farm_id': 'f1', 'notes': 'old', 'qa_boolean_flag': 'true'}, 200));
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(GetTaskResponseDetails('t1', onlyFields: {'farm_id'})),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoadingDetails, 'isLoadingDetails', isTrue),
        isA<TaskState>().having((s) => s.currentTaskResponse, 'currentTaskResponse', {'farm_id': 'f1'}),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'with an empty onlyFields set, prefills nothing',
      build: () {
        final client = MockClient((request) async => jsonResponse({'notes': 'old'}, 200));
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(GetTaskResponseDetails('t1', onlyFields: {})),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoadingDetails, 'isLoadingDetails', isTrue),
        isA<TaskState>().having((s) => s.currentTaskResponse, 'currentTaskResponse', isEmpty),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'multi-submit ignores a queued PENDING row (a previous submission, not this one)',
      setUp: () => FlutterSecureStorage.setMockInitialValues({
        'pending_task_queue': jsonEncode([
          {'task_id': 't1', 'answer': {'farm_id': 'queued', 'notes': 'queued'}, 'is_draft': false, 'status': 'PENDING'},
        ]),
      }),
      build: () {
        final client = MockClient((request) async => jsonResponse({'farm_id': 'f1', 'notes': 'old'}, 200));
        return TaskBloc(taskService: TaskService(client: client));
      },
      act: (bloc) => bloc.add(GetTaskResponseDetails('t1', onlyFields: {'farm_id'})),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoadingDetails, 'isLoadingDetails', isTrue),
        isA<TaskState>().having((s) => s.currentTaskResponse, 'currentTaskResponse', {'farm_id': 'f1'}),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'a saved draft is restored whole, even for multi-submit',
      setUp: () => FlutterSecureStorage.setMockInitialValues({
        'pending_task_queue': jsonEncode([
          {'task_id': 't1', 'answer': {'farm_id': 'f2', 'notes': 'half done'}, 'is_draft': true, 'status': 'DRAFT'},
        ]),
      }),
      build: () => TaskBloc(taskService: TaskService(client: MockClient((r) async => jsonResponse({}, 200)))),
      act: (bloc) => bloc.add(GetTaskResponseDetails('t1', onlyFields: {'farm_id'})),
      wait: _queueDelay,
      expect: () => [
        isA<TaskState>().having((s) => s.isLoadingDetails, 'isLoadingDetails', isTrue),
        isA<TaskState>().having(
          (s) => s.currentTaskResponse,
          'currentTaskResponse',
          {'farm_id': 'f2', 'notes': 'half done'},
        ),
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
        // Written via ServiceProvider, which is backed by flutter_secure_storage
        // (APP-2), not SharedPreferences.
        final queue = jsonDecode((await _secureStorage.read(key: 'pending_task_queue'))!) as List;
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
        final queue = jsonDecode((await _secureStorage.read(key: 'pending_task_queue'))!) as List;
        expect(queue.first['status'], 'PENDING');
      },
    );
  });

  // Multi-submit: several rows for one task can sit in the offline queue at
  // once. They used to be keyed by task_id alone.
  group('offline queue with several rows per task', () {
    const syncWait = Duration(milliseconds: 2500);

    Future<List<dynamic>> readQueue() async =>
        jsonDecode((await _secureStorage.read(key: 'pending_task_queue'))!) as List;

    blocTest<TaskBloc, TaskState>(
      'two failed submits for the same task both stay queued with distinct queue_ids',
      setUp: () => FlutterSecureStorage.setMockInitialValues({}),
      build: () => TaskBloc(
        taskService: TaskService(client: MockClient((r) async => http.Response('error', 500))),
      ),
      act: (bloc) async {
        bloc.add(SubmitTaskAction('t1', 'harvest_grade_detail', {'grade': 'A'}));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        bloc.add(SubmitTaskAction('t1', 'harvest_grade_detail', {'grade': 'B'}));
      },
      wait: const Duration(milliseconds: 1500),
      verify: (_) async {
        final queue = await readQueue();
        expect(queue.map((i) => i['answer']['grade']), ['A', 'B']);
        expect(queue.map((i) => i['queue_id']).toSet(), hasLength(2));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'saving a draft again replaces the previous draft instead of appending',
      setUp: () => FlutterSecureStorage.setMockInitialValues({}),
      build: () => TaskBloc(taskService: TaskService(client: MockClient((r) async => jsonResponse({}, 200)))),
      act: (bloc) async {
        bloc.add(SubmitTaskAction('t1', 'activity', {'note': 'first'}, isDraft: true));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        bloc.add(SubmitTaskAction('t1', 'activity', {'note': 'second'}, isDraft: true));
      },
      wait: const Duration(milliseconds: 1500),
      verify: (_) async {
        final queue = await readQueue();
        expect(queue, hasLength(1));
        expect(queue.single['answer']['note'], 'second');
      },
    );

    final requests = <http.Request>[];

    blocTest<TaskBloc, TaskState>(
      'multi-submit rows are all sent even though the task already has an answer',
      setUp: () {
        requests.clear();
        FlutterSecureStorage.setMockInitialValues({
          'pending_task_queue': jsonEncode([
            {'task_id': 't1', 'answer': {'grade': 'A'}, 'is_draft': false, 'is_edit': false, 'is_multiple_submit': true},
            {'task_id': 't1', 'answer': {'grade': 'B'}, 'is_draft': false, 'is_edit': false, 'is_multiple_submit': true},
          ]),
        });
      },
      build: () => TaskBloc(
        taskService: TaskService(
          client: MockClient((r) async {
            requests.add(r);
            if (r.method == 'GET' && r.url.path.endsWith('/tasks/t1')) {
              return jsonResponse({'answer': {'grade': 'earlier'}}, 200);
            }
            if (r.method == 'GET') return jsonResponse([], 200);
            return jsonResponse({}, 201);
          }),
        ),
      ),
      act: (bloc) => bloc.add(TriggerPendingQueueSync(DateTime(2026, 1, 11))),
      wait: syncWait,
      verify: (bloc) async {
        final posts = requests.where((r) => r.method == 'POST').toList();
        expect(posts.map((r) => jsonDecode(r.body)['answer']['grade']), ['A', 'B']);
        expect(bloc.state.pendingConflicts, isEmpty);
        expect(await readQueue(), isEmpty);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'a single-submit row whose task already has an answer is still held as a conflict',
      setUp: () {
        requests.clear();
        FlutterSecureStorage.setMockInitialValues({
          'pending_task_queue': jsonEncode([
            {'task_id': 't1', 'answer': {'note': 'x'}, 'is_draft': false, 'is_edit': false},
          ]),
        });
      },
      build: () => TaskBloc(
        taskService: TaskService(
          client: MockClient((r) async {
            requests.add(r);
            if (r.method == 'GET' && r.url.path.endsWith('/tasks/t1')) {
              return jsonResponse({'answer': {'note': 'server'}}, 200);
            }
            if (r.method == 'GET') return jsonResponse([], 200);
            return jsonResponse({}, 201);
          }),
        ),
      ),
      act: (bloc) => bloc.add(TriggerPendingQueueSync(DateTime(2026, 1, 11))),
      wait: syncWait,
      verify: (bloc) async {
        expect(requests.where((r) => r.method == 'POST'), isEmpty);
        expect(bloc.state.pendingConflicts, hasLength(1));
        expect(await readQueue(), hasLength(1));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'a row whose send fails stays in the queue instead of being dropped',
      setUp: () {
        FlutterSecureStorage.setMockInitialValues({
          'pending_task_queue': jsonEncode([
            {'task_id': 't1', 'answer': {'grade': 'A'}, 'is_draft': false, 'is_edit': false, 'is_multiple_submit': true},
          ]),
        });
      },
      build: () => TaskBloc(
        taskService: TaskService(
          client: MockClient((r) async {
            if (r.method == 'GET') return jsonResponse([], 200);
            return http.Response('error', 500);
          }),
        ),
      ),
      act: (bloc) => bloc.add(TriggerPendingQueueSync(DateTime(2026, 1, 11))),
      wait: syncWait,
      verify: (_) async {
        final queue = await readQueue();
        expect(queue, hasLength(1));
        expect(queue.single['queue_id'], isNotNull);
      },
    );
  });

  // SubmitTaskAction's result completer: the form shows สำเร็จ / ไม่สำเร็จ
  // from it, so it must say what really happened.
  group('SubmitTaskAction result', () {
    Future<SubmitResult> submitWith(http.Client client, {bool isDraft = false}) async {
      final bloc = TaskBloc(taskService: TaskService(client: client));
      final result = Completer<SubmitResult>();
      bloc.add(SubmitTaskAction('t1', 'activity', {'note': 'x'}, isDraft: isDraft, result: result));
      return result.future.timeout(const Duration(seconds: 5));
    }

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('accepted by the server -> sent, and nothing is left in the queue', () async {
      final result = await submitWith(MockClient((r) async => jsonResponse({}, 201)));
      expect(result.outcome, SubmitOutcome.sent);
      await Future<void>.delayed(_queueDelay);
      final stored = await _secureStorage.read(key: 'pending_task_queue');
      expect(stored == null ? <dynamic>[] : jsonDecode(stored) as List, isEmpty);
    });

    // docs-and-plan#223: a rejected answer used to be queued as PENDING and
    // reported as "saved offline", then rejected again on every sync.
    test('the server rejects the answer -> rejected with its reason, kept as a draft', () async {
      final result = await submitWith(
        MockClient((r) async => jsonResponse({'error': 'ข้อมูลไม่ผ่านการตรวจสอบ'}, 400)),
      );
      expect(result.outcome, SubmitOutcome.rejected);
      expect(result.serverError, 'ข้อมูลไม่ผ่านการตรวจสอบ');
      final queue = jsonDecode((await _secureStorage.read(key: 'pending_task_queue'))!) as List;
      expect(queue.single['status'], 'DRAFT');
      expect(queue.single['is_draft'], true);
    });

    test('a server-side failure (5xx) -> savedOffline, queued to retry', () async {
      final result = await submitWith(
        MockClient((r) async => jsonResponse({'error': 'internal'}, 500)),
      );
      expect(result.outcome, SubmitOutcome.savedOffline);
      final queue = jsonDecode((await _secureStorage.read(key: 'pending_task_queue'))!) as List;
      expect(queue.single['status'], 'PENDING');
    });

    test('an expired session (401) -> savedOffline, retried after login', () async {
      final result = await submitWith(
        MockClient((r) async => jsonResponse({'error': 'Session expired'}, 401)),
      );
      expect(result.outcome, SubmitOutcome.savedOffline);
    });

    test('no network -> savedOffline, queued to retry', () async {
      final result = await submitWith(
        MockClient((r) async => throw http.ClientException('offline')),
      );
      expect(result.outcome, SubmitOutcome.savedOffline);
      expect(result.serverError, isNull);
    });

    test('a draft -> draftSaved, never sent', () async {
      final result = await submitWith(
        MockClient((r) async => fail('a draft must never be sent')),
        isDraft: true,
      );
      expect(result.outcome, SubmitOutcome.draftSaved);
    });
  });
}

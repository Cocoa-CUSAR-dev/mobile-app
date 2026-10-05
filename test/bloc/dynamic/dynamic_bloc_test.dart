// Unit tests for lib/bloc/dynamic/dynamic.dart.
//
// DynamicBloc now loads its form definition live from the backend via
// DynamicApiService.fetchTaskForm (GET /tasks/:taskId/form), replacing the
// old assets/schema.json read — so, unlike before, this can be tested
// entirely through the MockClient DI seam with no rootBundle/asset-loading
// environment quirks. The TaskBloc collaborator is wired to a
// TaskService(client: MockClient(...)) so no real network call happens
// when DynamicBloc forwards work to it.

import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TaskBloc buildTaskBloc() {
    final client = MockClient((request) async => jsonResponse({}, 200));
    return TaskBloc(taskService: TaskService(client: client));
  }

  Map<String, dynamic> formWith(List<Map<String, dynamic>> questions) => {
    'sections': [
      {
        'isActive': true,
        'sortOrder': 1,
        'questions': questions,
      },
    ],
  };

  group('LoadSchemaAndData', () {
    blocTest<DynamicBloc, DynamicState>(
      'fetches the task form and emits DynamicReady',
      build: () {
        final client = MockClient((request) async {
          // The bloc now also asks GET /tasks/t1/autofill (US2-5) -- nothing
          // to offer here.
          if (request.url.path.endsWith('/autofill')) return http.Response('', 204);
          expect(request.url.toString(), 'https://mobile-backend-2-t8h6.onrender.com/tasks/t1/form');
          return jsonResponse({
            'form': formWith([
              {'fieldName': 'first_name', 'label': 'ชื่อจริง', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
            ]),
          }, 200);
        });
        return DynamicBloc(taskBloc: buildTaskBloc(), apiOverride: DynamicApiService(client: client));
      },
      act: (bloc) => bloc.add(LoadSchemaAndData('farmer', 't1')),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicReady>().having((s) => s.form, 'form', isNotEmpty),
      ],
    );

    // Only the question ticked "Reuse answer" is prefilled when the form is
    // multi-submit; a single-submit form still prefills every answer.
    for (final multi in [true, false]) {
      late TaskBloc taskBloc;

      blocTest<DynamicBloc, DynamicState>(
        multi
            ? 'multi-submit form prefills only carryForward answers'
            : 'single-submit form prefills every previous answer',
        build: () {
          taskBloc = TaskBloc(
            taskService: TaskService(
              client: MockClient((request) async => jsonResponse({'farm_id': 'f1', 'notes': 'old'}, 200)),
            ),
          );
          final client = MockClient((request) async => jsonResponse({
            'form': {
              ...formWith([
                {'fieldName': 'notes', 'inputType': 'VARCHAR', 'isActive': true, 'carryForward': false, 'sortOrder': 0},
                {'fieldName': 'farm_id', 'inputType': 'OPTION', 'isActive': true, 'carryForward': true, 'sortOrder': 1},
              ]),
              'isMultipleSubmit': multi,
            },
          }, 200));
          return DynamicBloc(
            taskBloc: taskBloc,
            apiOverride: DynamicApiService(client: client),
            taskServiceOverride: TaskService(
              client: MockClient((request) async => jsonResponse({'farm_id': 'f1', 'notes': 'old'}, 200)),
            ),
          );
        },
        act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
        wait: const Duration(milliseconds: 700),
        verify: (_) => expect(
          taskBloc.state.currentTaskResponse,
          multi ? {'farm_id': 'f1'} : {'farm_id': 'f1', 'notes': 'old'},
        ),
      );
    }

    blocTest<DynamicBloc, DynamicState>(
      'emits DynamicError when the backend response has no form',
      build: () {
        final client = MockClient((request) async => jsonResponse({}, 200));
        return DynamicBloc(taskBloc: buildTaskBloc(), apiOverride: DynamicApiService(client: client));
      },
      act: (bloc) => bloc.add(LoadSchemaAndData('farmer', 't1')),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicError>(),
      ],
    );

    blocTest<DynamicBloc, DynamicState>(
      'emits DynamicError when the request fails and nothing is cached',
      build: () {
        final client = MockClient((request) async => throw Exception('offline'));
        return DynamicBloc(taskBloc: buildTaskBloc(), apiOverride: DynamicApiService(client: client));
      },
      act: (bloc) => bloc.add(LoadSchemaAndData('farmer', 't1')),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicError>(),
      ],
    );
  });

  group('SubmitForm', () {
    blocTest<DynamicBloc, DynamicState>(
      'parses field types per the fetched form and emits DynamicSuccess',
      build: () {
        final client = MockClient((request) async => jsonResponse({
          'form': formWith([
            {'fieldName': 'age', 'label': 'อายุ', 'inputType': 'INT', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
          ]),
        }, 200));
        return DynamicBloc(taskBloc: buildTaskBloc(), apiOverride: DynamicApiService(client: client));
      },
      act: (bloc) => bloc.add(
        SubmitForm(handler: 'farmer', taskId: 't1', data: {'age': '30'}),
      ),
      // TaskBloc rewrites the local queue after a 500ms simulated delay --
      // wait it out here, or that write lands in the NEXT test and silently
      // replaces whatever queue it seeded (caught by the autofill draft test).
      wait: const Duration(milliseconds: 1200),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicSuccess>(),
      ],
    );

    blocTest<DynamicBloc, DynamicState>(
      'emits DynamicError instead of throwing when the form fetch fails',
      build: () {
        final client = MockClient((request) async => throw Exception('offline'));
        return DynamicBloc(taskBloc: buildTaskBloc(), apiOverride: DynamicApiService(client: client));
      },
      act: (bloc) => bloc.add(
        SubmitForm(handler: 'farmer', taskId: 't1', data: const {}),
      ),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicError>(),
      ],
    );
  });

  // US2-5: "use last time's answers". One test per row of the design doc's
  // §3.2 table, plus the parts of the offer the farmer actually reads.
  group('autofill offer', () {
    // ServiceProvider's local queue has a real 500ms simulated delay, and the
    // bloc reads it before any network call -- long enough for both.
    const settle = Duration(milliseconds: 1500);

    // The form every case opens: free text, an OPTION, a BOOLEAN. Ordered
    // deliberately out of id order so "form order" is actually tested.
    Map<String, dynamic> activityForm({bool multi = false}) => {
      ...formWith([
        {'fieldName': 'description', 'label': 'รายละเอียด', 'inputType': 'VARCHAR', 'isActive': true, 'sortOrder': 3},
        {
          'fieldName': 'plot_id', 'label': 'แปลงที่ดำเนินการ', 'inputType': 'OPTION', 'isActive': true, 'sortOrder': 1,
          'choices': [{'id': 'plot-a', 'name': 'แปลง A'}, {'id': 'plot-b', 'name': 'แปลง B'}],
        },
        {'fieldName': 'is_quality_damage', 'label': 'เสียหายไหม', 'inputType': 'BOOLEAN', 'isActive': true, 'sortOrder': 2},
      ]),
      'isMultipleSubmit': multi,
    };

    const lastAnswer = {
      'submitted_at': '2026-09-30T08:12:00Z',
      'answer': {
        'description': 'ฉีดพ่นรอบโคน',
        'plot_id': 'plot-a',
        'is_quality_damage': false,
        // On the farmer's last form but not this one -- never shown or used.
        'retired_field': 'x',
      },
    };

    // Everything one case needs: which requests were made, and a bloc wired
    // to answer them.
    late List<String> requested;

    DynamicBloc buildBloc({
      bool multi = false,
      Object? autofill = lastAnswer, // a Map = 200, null = 204, Exception = offline
      bool taskHasRowOnServer = false,
    }) {
      requested = [];
      final api = MockClient((request) async {
        requested.add(request.url.path);
        if (request.url.path.endsWith('/autofill')) {
          if (autofill is Exception) throw autofill;
          if (autofill == null) return http.Response('', 204);
          return jsonResponse(autofill, 200);
        }
        return jsonResponse({'form': activityForm(multi: multi)}, 200);
      });
      final tasks = MockClient((request) async {
        requested.add(request.url.path);
        return taskHasRowOnServer
            ? jsonResponse({'description': 'an earlier row'}, 200)
            : jsonResponse({'error': 'ไม่พบประวัติการส่งงานนี้'}, 404);
      });
      return DynamicBloc(
        taskBloc: TaskBloc(taskService: TaskService(client: tasks)),
        apiOverride: DynamicApiService(client: api),
        taskServiceOverride: TaskService(client: tasks),
      );
    }

    void seedQueue(List<Map<String, dynamic>> items) {
      final queue = jsonEncode(items);
      SharedPreferences.setMockInitialValues({'pending_task_queue': queue});
      FlutterSecureStorage.setMockInitialValues({'pending_task_queue': queue});
    }

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    final offered = isA<DynamicReady>().having((s) => s.autofillOffer, 'autofillOffer', isNotNull);
    final plainForm = isA<DynamicReady>().having((s) => s.autofillOffer, 'autofillOffer', isNull);

    blocTest<DynamicBloc, DynamicState>(
      'a local draft wins -- no offer, and no network call to ask for one',
      setUp: () => seedQueue([
        {'task_id': 't1', 'answer': {'description': 'half done'}, 'is_draft': true},
      ]),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm],
      verify: (_) => expect(requested, isNot(contains('/tasks/t1/autofill'))),
    );

    blocTest<DynamicBloc, DynamicState>(
      'single-submit already answered offline (queued, waiting to sync) -- edit mode, no offer',
      setUp: () => seedQueue([
        {'task_id': 't1', 'answer': {'description': 'sent offline'}, 'is_draft': false},
      ]),
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm],
      verify: (_) => expect(requested, isNot(contains('/tasks/t1/autofill'))),
    );

    blocTest<DynamicBloc, DynamicState>(
      'single-submit already answered on the server -- the server says 204, no offer',
      build: () => buildBloc(autofill: null),
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm],
    );

    blocTest<DynamicBloc, DynamicState>(
      'single-submit never answered -- asks, and offers on 200',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      // The form opens first and the offer follows: opening never waits on it.
      expect: () => [isA<DynamicLoading>(), plainForm, offered],
      verify: (_) => expect(requested, contains('/tasks/t1/autofill')),
    );

    blocTest<DynamicBloc, DynamicState>(
      'multi-submit, first row (no row on this task yet) -- offers',
      build: () => buildBloc(multi: true),
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm, offered],
    );

    blocTest<DynamicBloc, DynamicState>(
      'multi-submit, a later row -- no offer (carry-forward already covers it)',
      build: () => buildBloc(multi: true, taskHasRowOnServer: true),
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm],
      verify: (_) => expect(requested, isNot(contains('/tasks/t1/autofill'))),
    );

    blocTest<DynamicBloc, DynamicState>(
      'offline -- the form still opens, blank, with no offer and no error',
      build: () => buildBloc(autofill: Exception('no network')),
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      expect: () => [isA<DynamicLoading>(), plainForm],
    );

    blocTest<DynamicBloc, DynamicState>(
      'the preview is in form order, shows choice names not ids, and skips fields not on this form',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSchemaAndData('farm_activity', 't1')),
      wait: settle,
      verify: (bloc) {
        final offer = (bloc.state as DynamicReady).autofillOffer!;
        expect(
          offer.preview.map((line) => '${line.label}: ${line.value}').toList(),
          ['แปลงที่ดำเนินการ: แปลง A', 'เสียหายไหม: ไม่', 'รายละเอียด: ฉีดพ่นรอบโคน'],
        );
        // What gets applied is the raw values (ids), and only this form's fields.
        expect(offer.answer, {'description': 'ฉีดพ่นรอบโคน', 'plot_id': 'plot-a', 'is_quality_damage': false});
        expect(offer.submittedAt, DateTime.utc(2026, 9, 30, 8, 12).toLocal());
      },
    );

    blocTest<DynamicBloc, DynamicState>(
      'AutofillOfferHandled clears the offer, so it is shown once',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadSchemaAndData('farm_activity', 't1'));
        await Future<void>.delayed(settle);
        bloc.add(AutofillOfferHandled());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<DynamicLoading>(), plainForm, offered, plainForm],
    );
  });

  group('formatThaiShortDate', () {
    test('day, Thai short month, Buddhist Era year', () {
      expect(formatThaiShortDate(DateTime(2026, 9, 30)), '30 ก.ย. 2569');
      expect(formatThaiShortDate(DateTime(2027, 1, 2)), '2 ม.ค. 2570');
    });
  });
}

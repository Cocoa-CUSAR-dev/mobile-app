// Unit tests for lib/bloc/dynamic/dynamic.dart.
//
// DynamicBloc now loads its form definition live from the backend via
// DynamicApiService.fetchTaskForm (GET /tasks/:taskId/form), replacing the
// old assets/schema.json read — so, unlike before, this can be tested
// entirely through the MockClient DI seam with no rootBundle/asset-loading
// environment quirks. The TaskBloc collaborator is wired to a
// TaskService(client: MockClient(...)) so no real network call happens
// when DynamicBloc forwards work to it.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

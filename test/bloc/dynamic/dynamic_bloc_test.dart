// Unit tests for lib/bloc/dynamic/dynamic.dart.
//
// LoadSchemaAndData/SubmitForm both read assets/schema.json via rootBundle,
// which flutter_test's binding loads for real from disk (declared as an
// asset in pubspec.yaml) — no mocking needed for that part. The TaskBloc
// collaborator is wired to a TaskService(client: MockClient(...)) so no
// real network call happens when DynamicBloc forwards work to it.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The very first rootBundle.loadString call in a test run does real cold
  // disk I/O and can take longer than bloc_test's default settle window, so
  // pre-warm the (process-wide) asset cache before any blocTest runs.
  setUpAll(() async {
    await rootBundle.loadString('assets/schema.json');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TaskBloc buildTaskBloc() {
    final client = MockClient((request) async => jsonResponse({}, 200));
    return TaskBloc(taskService: TaskService(client: client));
  }

  group('LoadSchemaAndData', () {
    blocTest<DynamicBloc, DynamicState>(
      'loads the user_account schema and emits DynamicReady',
      build: () => DynamicBloc(taskBloc: buildTaskBloc()),
      act: (bloc) => bloc.add(LoadSchemaAndData('user_account', 't1')),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicReady>().having((s) => s.schema['properties'], 'properties', isNotEmpty),
      ],
    );

    blocTest<DynamicBloc, DynamicState>(
      'an unknown handler emits DynamicError',
      build: () => DynamicBloc(taskBloc: buildTaskBloc()),
      act: (bloc) => bloc.add(LoadSchemaAndData('no_such_table', 't1')),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicError>(),
      ],
    );
  });

  group('SubmitForm', () {
    blocTest<DynamicBloc, DynamicState>(
      'parses field types per the schema, generates a key, and emits DynamicSuccess',
      build: () => DynamicBloc(taskBloc: buildTaskBloc()),
      act: (bloc) => bloc.add(
        SubmitForm(
          handler: 'user_account',
          taskId: 't1',
          data: {'username': 'somchai'},
        ),
      ),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicSuccess>(),
      ],
    );

    blocTest<DynamicBloc, DynamicState>(
      'an unknown handler emits DynamicError instead of throwing',
      build: () => DynamicBloc(taskBloc: buildTaskBloc()),
      act: (bloc) => bloc.add(
        SubmitForm(handler: 'no_such_table', taskId: 't1', data: const {}),
      ),
      expect: () => [
        isA<DynamicLoading>(),
        isA<DynamicError>(),
      ],
    );
  });
}

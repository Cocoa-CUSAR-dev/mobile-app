// Unit tests for lib/services/task_service.dart.

import 'dart:convert';

import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getTasksByDate', () {
    test('sends the date as a yyyy-MM-dd query parameter', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['date'], '2026-01-11');
        return jsonResponse([
          {'task_id': 't1', 'title': 'ตัดหญ้า'},
        ], 200);
      });

      final tasks = await TaskService(client: client).getTasksByDate(DateTime(2026, 1, 11));

      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'ตัดหญ้า');
    });
  });

  group('getTaskResponse', () {
    test('returns the raw answer map on success', () async {
      final client = MockClient((request) async {
        return jsonResponse({'note': 'done'}, 200);
      });

      final response = await TaskService(client: client).getTaskResponse('t1');

      expect(response, {'note': 'done'});
    });

    test('returns null instead of throwing when the request fails', () async {
      final client = MockClient((request) async => http.Response('not found', 404));

      final response = await TaskService(client: client).getTaskResponse('missing');

      expect(response, isNull);
    });
  });

  group('submitTask', () {
    test('posts task_id and answer together', () async {
      Map<String, dynamic>? body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse({}, 200);
      });

      await TaskService(client: client).submitTask('t1', {'note': 'x'});

      expect(body, {
        'task_id': 't1',
        'answer': {'note': 'x'},
      });
    });
  });

  group('deleteTask', () {
    test('sends a DELETE request for the given id', () async {
      var deletedPath = '';
      final client = MockClient((request) async {
        deletedPath = request.url.path;
        return http.Response('', 200);
      });

      await TaskService(client: client).deleteTask('t1');

      expect(deletedPath, '/tasks/t1');
    });
  });
}

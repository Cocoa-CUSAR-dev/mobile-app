// Unit tests for lib/services/task_service.dart.

import 'dart:convert';

import 'package:cocoa_supply/services/service_provider.dart';
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
    test('posts the answer to /tasks/<taskId>/responses, the task id only in the URL', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return jsonResponse({}, 200);
      });

      await TaskService(client: client).submitTask('t1', {'note': 'x'});

      expect(sent.method, 'POST');
      expect(sent.url.toString(), '$testBaseUrl/api/v1/tasks/t1/responses');
      expect(jsonDecode(sent.body), {
        'answer': {'note': 'x'},
      });
    });
  });

  group('updateTask', () {
    test('edits the newest answer: finds its id, then PUTs to /tasks/<taskId>/responses/<id>', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          // newest first, as the backend lists them
          return jsonResponse([
            {'response_id': 'r-new', 'answer': {'note': 'b'}},
            {'response_id': 'r-old', 'answer': {'note': 'a'}},
          ], 200);
        }
        return jsonResponse({}, 200);
      });

      await TaskService(client: client).updateTask('t1', {'note': 'c'});

      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'GET /api/v1/tasks/t1/responses',
        'PUT /api/v1/tasks/t1/responses/r-new',
      ]);
      expect(jsonDecode(requests.last.body), {
        'answer': {'note': 'c'},
      });
    });

    test('says so when the task has no answer to edit, and sends nothing', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return jsonResponse([], 200);
      });

      await expectLater(
        TaskService(client: client).updateTask('t1', {'note': 'c'}),
        throwsA(isA<ServerRejection>().having((e) => e.statusCode, 'statusCode', 404)),
      );
      expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    });
  });
}

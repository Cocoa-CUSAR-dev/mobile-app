// Unit tests for lib/services/batch_service.dart.
//
// BatchService wraps a ServiceProvider<Batch> configured with isRealApi:
// true, so getBatches() normally hits `GET $testBaseUrl/batchs`.
// We inject a MockClient (from package:http/testing.dart) via the
// `client` constructor param added to BatchService/ServiceProvider for
// testability, so no real network call ever happens here.

import 'dart:convert';

import 'package:cocoa_supply/services/batch_service.dart';
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

  test('getBatches returns parsed batches on a 200 response', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$testBaseUrl/batchs');
      return jsonResponse([
        {'batch_id': 1, 'origin': 'ริมรั้ว', 'quantity_kg': '5.0'},
      ], 200);
    });

    final service = BatchService(client: client);
    final batches = await service.getBatches();

    expect(batches, hasLength(1));
    expect(batches.first.batchId, '1');
    expect(batches.first.origin, 'ริมรั้ว');
  });

  test('getBatches falls back to cache on a non-200 response', () async {
    SharedPreferences.setMockInitialValues({
      'batch_data': jsonEncode([
        {'batch_id': 'cached', 'origin': 'cache'},
      ]),
    });

    final client = MockClient((request) async => http.Response('error', 500));

    final service = BatchService(client: client);
    final batches = await service.getBatches();

    expect(batches, hasLength(1));
    expect(batches.first.batchId, 'cached');
  });

  test('getBatches falls back to cache when the request throws', () async {
    SharedPreferences.setMockInitialValues({
      'batch_data': jsonEncode([
        {'batch_id': 'cached'},
      ]),
    });

    final client = MockClient((request) async => throw Exception('network down'));

    final service = BatchService(client: client);
    final batches = await service.getBatches();

    expect(batches, hasLength(1));
    expect(batches.first.batchId, 'cached');
  });

  test('getBatches returns an empty list when the response and cache are both empty', () async {
    final client = MockClient((request) async => http.Response('error', 500));

    final service = BatchService(client: client);
    final batches = await service.getBatches();

    expect(batches, isEmpty);
  });
}

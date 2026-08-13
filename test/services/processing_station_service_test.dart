// Unit tests for lib/services/processing_station_service.dart.

import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:cocoa_supply/services/processing_station_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getStations', () {
    test('returns parsed stations on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/processing_stations');
        return jsonResponse([
          {'processing_station_id': 1, 'processing_station_name': 'ศูนย์แปรรูปแม่จัน'},
        ], 200);
      });

      final stations = await ProcessingStationService(client: client).getStations();

      expect(stations, hasLength(1));
      expect(stations.first.processingStationName, 'ศูนย์แปรรูปแม่จัน');
    });

    test('falls back to cache on a non-200 response', () async {
      SharedPreferences.setMockInitialValues({
        'processing_station_data': '[{"processing_station_id":"cached"}]',
      });
      final client = MockClient((request) async => jsonResponse('error', 500));

      final stations = await ProcessingStationService(client: client).getStations();

      expect(stations, hasLength(1));
      expect(stations.first.processingStationId, 'cached');
    });
  });

  group('saveStation', () {
    test('posts the station payload', () async {
      var posted = false;
      final client = MockClient((request) async {
        posted = request.method == 'POST';
        return jsonResponse({}, 200);
      });

      await ProcessingStationService(client: client).saveStation(
        ProcessingStation(processingStationId: '1', processingStationName: 'A'),
      );

      expect(posted, isTrue);
    });
  });
}

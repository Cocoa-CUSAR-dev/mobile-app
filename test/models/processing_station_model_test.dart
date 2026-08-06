// Unit tests for lib/models/processing_station_model.dart.

import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProcessingStation.fromJson', () {
    test('parses a fully-populated payload including nested batches', () {
      final station = ProcessingStation.fromJson({
        'processing_station_id': 1,
        'processing_station_name': 'ศูนย์แปรรูปแม่จัน',
        'hub_id': 2,
        'found_date': '2026-01-11T00:00:00.000Z',
        'processing_station_area': '10.0',
        'batches': [
          {'batch_id': 1, 'origin': 'ริมรั้ว'},
        ],
      });

      expect(station.processingStationId, '1');
      expect(station.processingStationName, 'ศูนย์แปรรูปแม่จัน');
      expect(station.processingStationArea, 10.0);
      expect(station.batches, hasLength(1));
      expect(station.batches!.first.origin, 'ริมรั้ว');
    });

    test('batches is null when absent from the payload', () {
      final station = ProcessingStation.fromJson({'processing_station_id': 1});
      expect(station.batches, isNull);
    });

    test('all fields are null when json is empty', () {
      final station = ProcessingStation.fromJson({});
      expect(station.processingStationId, isNull);
      expect(station.batches, isNull);
    });
  });

  group('ProcessingStation.toJson', () {
    test('round-trips scalar fields through fromJson/toJson', () {
      final original = ProcessingStation(
        processingStationId: '1',
        processingStationName: 'ศูนย์แปรรูปแม่จัน',
        hubId: '2',
        foundDate: DateTime.parse('2026-01-11T00:00:00.000Z'),
      );

      final roundTripped = ProcessingStation.fromJson(original.toJson());

      expect(roundTripped.processingStationId, original.processingStationId);
      expect(roundTripped.processingStationName, original.processingStationName);
      expect(roundTripped.hubId, original.hubId);
      expect(roundTripped.foundDate, original.foundDate);
    });
  });
}

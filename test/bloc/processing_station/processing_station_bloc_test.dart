// Unit tests for lib/bloc/processing_station/processing_station.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/processing_station/processing_station.dart';
import 'package:cocoa_supply/services/processing_station_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProcessingStationBloc', () {
    blocTest<ProcessingStationBloc, ProcessingStationState>(
      'emits [ProcessingStationLoading, ProcessingStationsLoaded] on success',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'processing_station_id': 1, 'processing_station_name': 'ศูนย์แปรรูปแม่จัน'},
          ], 200);
        });
        return ProcessingStationBloc(stationService: ProcessingStationService(client: client));
      },
      act: (bloc) => bloc.add(LoadProcessingStations()),
      expect: () => [
        isA<ProcessingStationLoading>(),
        isA<ProcessingStationsLoaded>()
            .having((s) => s.stations.first.processingStationName, 'name', 'ศูนย์แปรรูปแม่จัน'),
      ],
    );
  });
}

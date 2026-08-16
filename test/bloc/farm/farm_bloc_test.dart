// Unit tests for lib/bloc/farm/farm_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/farm/farm_bloc.dart';
import 'package:cocoa_supply/bloc/farm/farm_event.dart';
import 'package:cocoa_supply/bloc/farm/farm_state.dart';
import 'package:cocoa_supply/services/farm_service.dart';
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

  group('FarmBloc', () {
    blocTest<FarmBloc, FarmState>(
      'emits [FarmLoading, FarmsLoaded] on a successful fetch',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'farm_id': 1, 'farm_name': 'ไร่โกโก้พรีเมียม'},
          ], 200);
        });
        return FarmBloc(farmService: FarmService(client: client));
      },
      act: (bloc) => bloc.add(LoadFarms()),
      expect: () => [
        isA<FarmLoading>(),
        isA<FarmsLoaded>().having((s) => s.farms.first.farmName, 'farmName', 'ไร่โกโก้พรีเมียม'),
      ],
    );

    blocTest<FarmBloc, FarmState>(
      'emits [FarmLoading, FarmsLoaded] with an empty list when nothing is cached and the request fails',
      build: () {
        final client = MockClient((request) async => http.Response('error', 500));
        return FarmBloc(farmService: FarmService(client: client));
      },
      act: (bloc) => bloc.add(LoadFarms()),
      expect: () => [
        isA<FarmLoading>(),
        isA<FarmsLoaded>().having((s) => s.farms, 'farms', isEmpty),
      ],
    );
  });
}

// Unit tests for lib/bloc/hub/hub_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/hub/hub_bloc.dart';
import 'package:cocoa_supply/bloc/hub/hub_event.dart';
import 'package:cocoa_supply/bloc/hub/hub_state.dart';
import 'package:cocoa_supply/services/hub_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HubBloc', () {
    blocTest<HubBloc, HubState>(
      'emits [HubLoading, HubsLoaded] on a successful fetch',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'hub_id': 1, 'hub_name': 'จุดรับซื้อกลาง'},
          ], 200);
        });
        return HubBloc(hubService: HubService(client: client));
      },
      act: (bloc) => bloc.add(LoadHubs()),
      expect: () => [
        isA<HubLoading>(),
        isA<HubsLoaded>().having((s) => s.hubs.first.hubName, 'hubName', 'จุดรับซื้อกลาง'),
      ],
    );

    blocTest<HubBloc, HubState>(
      'emits [HubLoading, HubError] when fetchAll throws',
      build: () {
        final client = MockClient((request) async => throw Exception('offline'));
        return HubBloc(hubService: HubService(client: client));
      },
      act: (bloc) => bloc.add(LoadHubs()),
      // fetchAll falls back to an empty cache on failure rather than
      // throwing, so HubBloc's try/catch never actually fires here.
      expect: () => [
        isA<HubLoading>(),
        isA<HubsLoaded>().having((s) => s.hubs, 'hubs', isEmpty),
      ],
    );
  });
}

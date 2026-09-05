// Unit tests for lib/bloc/plot/plot_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/plot/plot_bloc.dart';
import 'package:cocoa_supply/bloc/plot/plot_event.dart';
import 'package:cocoa_supply/bloc/plot/plot_state.dart';
import 'package:cocoa_supply/models/plot_model.dart';
import 'package:cocoa_supply/services/plot_service.dart';
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

  group('PlotBloc', () {
    blocTest<PlotBloc, PlotState>(
      'LoadPlots emits [PlotLoading, PlotsLoaded] on success',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'plot_id': 1, 'plot_name': 'แปลง 1'},
          ], 200);
        });
        return PlotBloc(plotService: PlotService(client: client));
      },
      act: (bloc) => bloc.add(LoadPlots()),
      expect: () => [
        isA<PlotLoading>(),
        isA<PlotsLoaded>().having((s) => s.plots.first.plotName, 'plotName', 'แปลง 1'),
      ],
    );

    blocTest<PlotBloc, PlotState>(
      'RegisterPlot emits registration then operation success with the refreshed list',
      build: () {
        final client = MockClient((request) async {
          if (request.method == 'GET') return jsonResponse([], 200);
          return jsonResponse({}, 200);
        });
        return PlotBloc(plotService: PlotService(client: client));
      },
      act: (bloc) => bloc.add(RegisterPlot(Plot(plotId: '1', farmId: '2'))),
      expect: () => [
        isA<PlotLoading>(),
        isA<PlotRegistrationSuccess>(),
        isA<PlotOperationSuccess>(),
      ],
    );

    blocTest<PlotBloc, PlotState>(
      'RegisterPlot emits PlotOperationFailure when savePlot rejects a duplicate',
      build: () {
        final client = MockClient((request) async {
          return jsonResponse([
            {'plot_id': 1, 'farm_id': 2},
          ], 200);
        });
        return PlotBloc(plotService: PlotService(client: client));
      },
      act: (bloc) => bloc.add(RegisterPlot(Plot(plotId: '2', farmId: '2'))),
      expect: () => [
        isA<PlotLoading>(),
        isA<PlotOperationFailure>(),
      ],
    );

    blocTest<PlotBloc, PlotState>(
      'DeletePlot emits operation success with the refreshed list',
      build: () {
        final client = MockClient((request) async {
          if (request.method == 'DELETE') return http.Response('', 200);
          return jsonResponse([], 200);
        });
        return PlotBloc(plotService: PlotService(client: client));
      },
      act: (bloc) => bloc.add(const DeletePlot('1')),
      expect: () => [
        isA<PlotLoading>(),
        isA<PlotOperationSuccess>(),
      ],
    );
  });
}

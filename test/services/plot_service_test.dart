// Unit tests for lib/services/plot_service.dart.
//
// Known bug documented by the getPlotById test below: it filters by
// `p.farmId` instead of `p.plotId`, so it actually returns "the plot
// belonging to this farm" rather than "the plot with this id". The test
// pins the current (likely unintended) behavior rather than silently
// rewriting it — flagging for a human to confirm intent and fix.

import 'package:cocoa_supply/models/plot_model.dart';
import 'package:cocoa_supply/services/plot_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getPlots', () {
    test('returns parsed plots on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8080/plots');
        return jsonResponse([
          {'plot_id': 1, 'plot_name': 'แปลง 1'},
        ], 200);
      });

      final plots = await PlotService(client: client).getPlots();

      expect(plots, hasLength(1));
      expect(plots.first.plotName, 'แปลง 1');
    });
  });

  group('getPlotById (documented current behavior: filters by farmId, not plotId)', () {
    test('matches on farmId rather than plotId', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'plot_id': 1, 'farm_id': 99},
        ], 200);
      });

      final plot = await PlotService(client: client).getPlotById('99');

      expect(plot?.farmId, '99');
    });

    test('throws when no plot has a matching farmId', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'plot_id': 1, 'farm_id': 5},
        ], 200);
      });

      await expectLater(
        PlotService(client: client).getPlotById('1'),
        throwsStateError,
      );
    });
  });

  group('savePlot', () {
    test('rejects a plot whose farmId already exists', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'plot_id': 1, 'farm_id': 5},
        ], 200);
      });

      await expectLater(
        PlotService(client: client).savePlot(Plot(plotId: '2', farmId: '5')),
        throwsA(isA<Exception>()),
      );
    });
  });
}

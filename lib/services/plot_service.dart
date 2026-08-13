// lib/services/plot_service.dart

import 'package:cocoa_supply/models/plot_model.dart';
import 'package:cocoa_supply/services/service_provider.dart'; // Assume this exists
import 'package:http/http.dart' as http;

class PlotService {
  static const String _storageKey = 'plot_data';
  static const String _endpoint = '/plots'; // Mock endpoint

  PlotService({http.Client? client})
    : _provider = ServiceProvider<Plot>(
        storageKey: _storageKey,
        endpoint: _endpoint,
        isRealApi: true,
        client: client,
      );

  // ServiceProvider must be implemented to handle generic data fetching/saving
  final ServiceProvider<Plot> _provider;

  /// Fetch all plots
  Future<List<Plot>> getPlots({Map<String, dynamic>? queryParams}) async {
    return _provider.fetchData(
      Plot.fromJson,
      queryParams: queryParams,
    );
  }

  /// Fetch a single plot by ID
  Future<Plot?> getPlotById(String plotId) async {
    final all = await getPlots();
    return all.firstWhere((p) => p.farmId.toString() == plotId.toString());
  }

  /// Save new plot
  Future<void> savePlot(Plot newPlot) async {
    // Add business logic like checking for existing ID
    final existing = await getPlots();
    if (existing.any((p) => p.farmId == newPlot.farmId)) {
      throw Exception('Plot with this ID already exists.');
    }

    await _provider.postData(newPlot.toJson());
  }

  // /// Update existing plot
  // Future<void> updatePlot(Plot updatedPlot) async {
  //   // Use PUT or equivalent operation (mocked)
  //   await _provider.putData('farmId', updatedPlot.toJson());
  // }

  /// Delete plot
  Future<void> deletePlot(String plotId) async {
    // Use DELETE operation (mocked)
    await _provider.deleteData(plotId.toString());
  }
}

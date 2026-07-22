// lib/services/farm_service.dart

import 'package:cocoa_supply/models/farm_model.dart';
import 'package:cocoa_supply/services/service_provider.dart'; // Assume this exists

class FarmService {
  static const String _storageKey = 'farm_data';
  static const String _endpoint = '/farms'; // Mock endpoint
  
  // ServiceProvider must be implemented to handle generic data fetching/saving
  final ServiceProvider<Farm> _provider = ServiceProvider<Farm>(
    storageKey: _storageKey,
    endpoint: _endpoint,
    isRealApi: true
  );

  /// Fetch all farms
  Future<List<Farm>> getFarms({Map<String, dynamic>? queryParams}) async {
    return _provider.fetchData(
      Farm.fromJson,
      queryParams: queryParams,
    );
  }

  /// Fetch a single farm by ID
  Future<Farm?> getFarmById(String farmId) async {
    final all = await getFarms();
    return all.firstWhere((p) => p.farmId.toString() == farmId.toString());
  }

  /// Save new farm
  Future<void> saveFarm(Farm newFarm) async {
    // Add business logic like checking for existing ID
    final existing = await getFarms();
    if (existing.any((p) => p.farmId == newFarm.farmId)) {
      throw Exception('Farm with this ID already exists.');
    }

    await _provider.postData(newFarm.toJson());
  }

  // /// Update existing farm
  // Future<void> updateFarm(Farm updatedFarm) async {
  //   // Use PUT or equivalent operation (mocked)
  //   await _provider.putData('farmId', updatedFarm.toJson());
  // }

  /// Delete farm
  Future<void> deleteFarm(String farmId) async {
    // Use DELETE operation (mocked)
    await _provider.deleteData(farmId.toString());
  }
}

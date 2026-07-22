// lib/services/harvest_service.dart

import 'package:cocoa_supply/models/harvest_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class HarvestService {
  static const String _storageKey = 'harvest_data';
  static const String _endpoint = '/harvests';

  final ServiceProvider<Harvest> _provider = ServiceProvider<Harvest>(
    storageKey: _storageKey,
    endpoint: _endpoint,
    isRealApi: true,
  );

  /// ดึงรายการการเก็บเกี่ยวทั้งหมด
  Future<List<Harvest>> getHarvests() async {
    return _provider.fetchData(
      Harvest.fromJson,
    );
  }

  /// บันทึกการเก็บเกี่ยวใหม่
  Future<void> saveHarvest(Harvest harvest) async {
    await _provider.postData(harvest.toJson());
  }

  /// ลบข้อมูลการเก็บเกี่ยว
  Future<void> deleteHarvest(String id) async {
    await _provider.deleteData(id);
  }
}
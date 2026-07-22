// lib/services/hub_service.dart

import 'package:cocoa_supply/models/hub_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class HubService {
  static const String _storageKey = 'hub_data';
  static const String _endpoint = '/hubs'; // ปรับ Endpoint เป็น /hub
  
  // ใช้ ServiceProvider จัดการ Generic Data
  final ServiceProvider<Hub> _provider = ServiceProvider<Hub>(
    storageKey: _storageKey,
    endpoint: _endpoint,
    isRealApi: true,
  );

  /// ดึงข้อมูลทั้งหมดจาก Hub
  Future<List<Hub>> fetchAll() async {
    return _provider.fetchData(
      Hub.fromJson,
      queryParams: null,
    );
  }

  /// ค้นหาข้อมูลรายชิ้นใน Hub โดยใช้ ID
  Future<Hub?> fetchById(String id) async {
    final all = await fetchAll();
    // ค้นหาจาก hubId หรือ id ที่เกี่ยวข้อง
    try {
      return all.firstWhere((item) => item.hubId.toString() == id.toString());
    } catch (_) {
      return null;
    }
  }

  /// บันทึกข้อมูลใหม่ลงใน Hub
  Future<void> save(Hub data) async {
    final existing = await fetchAll();
    if (existing.any((item) => item.hubId == data.hubId)) {
      throw Exception('ข้อมูลชิ้นนี้มีอยู่ใน Hub แล้ว');
    }

    await _provider.postData(data.toJson());
  }

  // /// อัปเดตข้อมูลเดิมใน Hub
  // Future<void> update(Hub data) async {
  //   // ระบุ Key ที่ใช้ในการอ้างอิงเพื่อ Update (เช่น hubId)
  //   await _provider.putData('hubId', data.toJson());
  // }

  /// ลบข้อมูลออกจาก Hub
  Future<void> delete(String id) async {
    await _provider.deleteData(id.toString());
  }
}
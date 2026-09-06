import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

class DynamicApiService {
  DynamicApiService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// ดึงโครงสร้างฟอร์มสดสำหรับ task นี้ (แทนที่ assets/schema.json เดิม)
  /// คืนค่า { form: {...}, version: N } ตามที่ mobile-backend proxy ส่งมา
  /// แคชไว้ในเครื่องอัตโนมัติผ่าน ServiceProvider — เปิดฟอร์มได้แม้ออฟไลน์
  Future<Map<String, dynamic>> fetchTaskForm(String taskId) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: 'task_form',
      endpoint: '/tasks',
      isRealApi: true,
      client: _client,
    );

    return provider.fetchOneCached('$taskId/form');
  }

  /// ดึงข้อมูลตาม table
  // APP-6: was missing isRealApi: true (every other service in this app
  // sets it -- see batch_service.dart, harvest_service.dart, etc., and
  // fetchTaskForm/fetchConstants above/below in this same file). Without
  // it, ServiceProvider's constructor defaults to mock/local-only mode, so
  // this silently never hit the real backend, only read/wrote the local
  // cache.
  Future<List<Map<String, dynamic>>> fetchData(String tableName,
      {Map<String, dynamic>? queryParams}) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: '${tableName}_data',
      endpoint: '/$tableName',
      isRealApi: true,
      client: _client,
    );

    return provider.fetchData(
      (json) => Map<String, dynamic>.from(json),
      queryParams: queryParams,
    );
  }

  /// บันทึกข้อมูล (POST / PATCH)
  // APP-6: same missing isRealApi: true as fetchData above.
  Future<void> submitData(
    String tableName,
    Map<String, dynamic> data, {
    bool isEdit = false,
  }) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: '${tableName}_data',
      endpoint: '/$tableName',
      isRealApi: true,
      client: _client,
    );

    try {
      if (isEdit) {
        await provider.putData(data); // id มักเป็น value ตัวแรก ของ json
      } else {
        await provider.postData(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchConstants(String key,
      {Map<String, dynamic>? queryParams}) async {
    // 1. สร้าง Instance ของ ServiceProvider สำหรับ Constants
    // ปรับ endpoint ให้เป็นแบบ dynamic ตาม key ที่ส่งมา
    final service = ServiceProvider<Map<String, dynamic>>(
      storageKey: 'constants_$key', // เก็บลง storage แยกตามประเภท
      endpoint: '/constants/$key',
      isRealApi: true, // เปิดใช้งาน API จริง
      client: _client,
    );

    try {
      // 2. เรียก fetchData โดยส่ง 'creator' เป็นฟังก์ชันที่ return map ตรงๆß
      // เนื่องจากเราต้องการ data ดิบมาใช้งานใน UI แบบ dynamic
      final List<Map<String, dynamic>> results = await service.fetchData(
        (json) => json, // creator: รับ json map มาแล้วคืนค่าออกไปเลย
        queryParams: queryParams,
      );
      print(key);
      print(results);
      return results;
    } catch (e) {
      print('Error fetching constants for $key: $e');
      
      // 3. Fallback: กรณี Error หรือ Server ล่ม 
      // คุณสามารถเลือกได้ว่าจะคืนค่าว่าง [] หรือจะเอา Mock Data เดิมมาใส่ไว้ที่นี่
      return []; 
    }
  }
}
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

  /// US2-5: คำตอบครั้งล่าสุดของงานประเภทเดียวกัน สำหรับเสนอ "ใช้ข้อมูลเดิม"
  /// (GET /tasks/:taskId/autofill) -- คืน {submitted_at, answer} ที่ server
  /// คัดกรองมาแล้วด้วยกฎเดียวกับแชทบอท
  ///
  /// คืน null ในทุกกรณีที่ไม่มีอะไรให้เสนอ: 204 (ไม่มีประวัติ / ตอบงานนี้ไปแล้ว /
  /// ฟอร์มที่ต้องเลือกงานหลักก่อน), ออฟไลน์, timeout, error ใดๆ ก็ตาม เพราะ
  /// การเปิดฟอร์มต้องไม่มีวันติดอยู่ที่ข้อเสนอนี้ -- ไม่มีข้อเสนอ = ฟอร์มว่างเหมือนเดิม
  Future<Map<String, dynamic>?> fetchAutofill(String taskId) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: 'task_autofill',
      endpoint: '/tasks',
      isRealApi: true,
      client: _client,
    );
    try {
      final result = await provider.fetchOneOptional('$taskId/autofill');
      final answer = result?['answer'];
      if (answer is! Map<String, dynamic> || answer.isEmpty) return null;
      return result;
    } catch (_) {
      return null;
    }
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

  // APP-10: province/district/subdistrict never change during a session,
  // but every dropdown open called fetchConstants() again -- re-hitting
  // the network for the exact same list each time (confirmed live: opening
  // the same province/district dropdown twice logged two identical
  // fetches). In-memory cache keyed by key+queryParams so the same list is
  // only ever fetched once per session; a fresh app launch still fetches
  // normally.
  static final Map<String, List<Map<String, dynamic>>> _constantsCache = {};

  /// Drops everything cached by fetchConstants.
  ///
  /// The cache is static, so it outlives any one screen and any one signed-in
  /// user. Today it only ever holds public reference data (province, district,
  /// subdistrict), but fetchConstants takes an arbitrary `key` -- the day
  /// someone points it at something user-scoped, that data would follow the
  /// previous account into the next session. Called from AuthService.logout()
  /// so that cannot happen quietly.
  static void clearConstantsCache() => _constantsCache.clear();

  String _constantsCacheKey(String key, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) return key;
    final sortedEntries = queryParams.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final paramsPart = sortedEntries.map((e) => '${e.key}=${e.value}').join(',');
    return '$key?$paramsPart';
  }

  Future<List<Map<String, dynamic>>> fetchConstants(String key,
      {Map<String, dynamic>? queryParams}) async {
    final cacheKey = _constantsCacheKey(key, queryParams);
    final cached = _constantsCache[cacheKey];
    if (cached != null) return cached;

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
      // Deliberately not caching an empty list: a backend that answers 200
      // with [] during a deploy would otherwise leave that dropdown empty
      // for the rest of the session, with no way for the user to retry.
      if (results.isNotEmpty) _constantsCache[cacheKey] = results;
      return results;
    } catch (e) {
      print('Error fetching constants for $key: $e');

      // 3. Fallback: กรณี Error หรือ Server ล่ม
      // คุณสามารถเลือกได้ว่าจะคืนค่าว่าง [] หรือจะเอา Mock Data เดิมมาใส่ไว้ที่นี่
      return [];
    }
  }

  // APP-11: กรุงเทพมหานครใช้ "เขต"/"แขวง" ไม่ใช่ "อำเภอ"/"ตำบล" -- หน้าลงทะเบียน
  // ต้องรู้ชื่อจังหวัดที่เลือกอยู่ (ไม่ใช่แค่ id) เพื่อสลับ label ให้ถูก แต่
  // onChanged ของ dropdown จังหวัดส่งมาแค่ id เท่านั้น เลยต้องมีตัวช่วยย้อนดูชื่อ
  // จาก cache ของ fetchConstants('province') ที่โหลดไว้แล้วตอนเปิด dropdown
  // จังหวัด (ไม่ต้อง fetch ซ้ำ)
  static String? lookupCachedProvinceName(String? provinceId) {
    if (provinceId == null) return null;
    final cached = _constantsCache['province'];
    if (cached == null) return null;
    for (final row in cached) {
      if (row['province_id']?.toString() == provinceId) {
        return row['province_name_th']?.toString();
      }
    }
    return null;
  }

  static bool isBangkokProvinceId(String? provinceId) {
    final name = lookupCachedProvinceName(provinceId);
    return name != null && name.contains('กรุงเทพ');
  }
}

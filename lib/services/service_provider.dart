import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceProvider<T> {
  final String storageKey;
  final String endpoint;
  final bool isRealApi;
  final bool useCookie;
  final String baseUrl = 'http://localhost:8080';

  static const String _cookieKey = 'auth_cookie';

  ServiceProvider({
    required this.storageKey,
    required this.endpoint,
    this.isRealApi = false,
    this.useCookie = true,
  });

  // --- PRIVATE HELPERS ---

  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> isLoggedIn() async {
    final uri = Uri.parse('$baseUrl/auth/me');
    try {
      // เพิ่ม timeout เพื่อป้องกันกรณีเชื่อมต่อนานเกินไป
      final prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString(_cookieKey);
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (cookie != null) 'Cookie': cookie,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        print('UNAUTHORIZED');
        logout();
        return false;
      }else if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final List roles = data['roles'] ?? [];
        if (roles.isEmpty){
          logout();
          return false;
        }
      }
      return cookie != null && cookie.isNotEmpty;
    } catch (e) {
      print(e);
      return false;
    }
    
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cookie = prefs.getString(_cookieKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (cookie != null && useCookie) 'Cookie': cookie,
    };
  }

  Future<void> _updateCookie(http.Response response) async {
    final String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null && rawCookie.isNotEmpty) {
      final String cookieToStore = rawCookie.split(';').first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cookieKey, cookieToStore);
    }
  }

  String _generateCacheKey(Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return storageKey;
    }
    
    // แปลง Map เป็น String เช่น {date: 2024-05-20, type: urgent} 
    // กลายเป็น storageKey_date=2024-05-20_type=urgent
    final sortedParams = Map.fromEntries(
        queryParams.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));
    
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('_');
        
    return '${storageKey}_$queryString';
  }

  // 2. ปรับปรุงการบันทึก (รับ key เพิ่ม)
  Future<void> _saveToLocal(dynamic data, String effectiveKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(effectiveKey, jsonEncode(data));
  }

  // 3. ปรับปรุงการดึงจาก Local (รับ key เพิ่ม)
  Future<List<T>> _fetchFromLocal(
    T Function(Map<String, dynamic>) creator,
    String effectiveKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(effectiveKey);
    if (dataString != null) {
      final List<dynamic> jsonData = jsonDecode(dataString);
      return jsonData.map((e) => creator(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // --- PUBLIC METHODS ---

  Future<List<T>> fetchData(
    T Function(Map<String, dynamic>) creator, {
    Map<String, dynamic>? queryParams,
  }) async {
    // สร้าง Key สำหรับ Cache โดยอิงตาม Query Params
    final effectiveKey = _generateCacheKey(queryParams);

    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      try {
        final response = await http
            .get(uri, headers: await _getHeaders())
            .timeout(const Duration(seconds: 10));

        await _updateCookie(response);

        if (response.statusCode == 200) {
          final List<dynamic> jsonData = jsonDecode(response.body);
          // บันทึกโดยใช้ effectiveKey
          await _saveToLocal(jsonData, effectiveKey);
          return jsonData
              .map((e) => creator(e as Map<String, dynamic>))
              .toList();
        } else {
          // กรณี Server Error (เช่น 500) ให้ดึงจาก Cache ที่ตรงกับ Query นี้
          return await _fetchFromLocal(creator, effectiveKey);
        }
      } catch (e) {
        print('Network Error: $e. Falling back to cache with key: $effectiveKey');
        return await _fetchFromLocal(creator, effectiveKey);
      }
    } else {
      await _simulateNetworkDelay();
      return await _fetchFromLocal(creator, effectiveKey);
    }
  }

  /// Post Data (POST) - เปลี่ยนจาก void เป็น Future<dynamic> เพื่อคืนค่าที่ Server ส่งมา
  Future<dynamic> postData(Map<String, dynamic> payload) async {
    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint');
      try {
        final response = await http.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(payload),
        );

        // อัปเดต Cookie จาก Response
        await _updateCookie(response);

        // 1. Decode แค่ครั้งเดียวเพื่อประสิทธิภาพ
        final dynamic responseData = jsonDecode(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // ใช้ช่วง 200-299 ครอบคลุมทั้ง OK (200), Created (201), No Content (204)
          print('POST Success: $responseData');
          return responseData;
        } else {
          // 2. ดึง Error Message อย่างปลอดภัย (ป้องกันกรณี responseData ไม่ใช่ Map หรือไม่มี key error)
          String errorMessage = 'Post Error';
          if (responseData is Map && responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData is Map && responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
          
          throw errorMessage;
        }
      } on FormatException catch (_) {
        // 3. จัดการกรณีที่ Response Body ไม่ใช่ JSON (เช่น Server ล่มแล้วพ่น HTML ออกมา)
        throw "เซิร์ฟเวอร์ตอบกลับผิดพลาด (Invalid JSON)";
      } catch (e) {
        // 4. จัดการ Error อื่นๆ เช่น No Internet หรือ Timeout
        rethrow;
      }
    } else {
      // Mock Logic: บันทึกลง Local และคืนค่า payload กลับไป
      await _simulateNetworkDelay();
      final prefs = await SharedPreferences.getInstance();
      final String? existingString = prefs.getString(storageKey);
      List<dynamic> existingData = existingString != null
          ? jsonDecode(existingString)
          : [];
      existingData.add(payload);
      await prefs.setString(storageKey, jsonEncode(existingData));
      return payload;
    }
  }

  /// Fetch a single object (GET) with local cache fallback, for endpoints
  /// keyed by more than a bare id (e.g. /tasks/:taskId/form). Mirrors
  /// fetchData's cache-then-serve behaviour, but for one JSON object
  /// instead of a list — needed so the offline-first requirement holds
  /// for endpoints like this one too.
  Future<Map<String, dynamic>> fetchOneCached(String pathSuffix) async {
    final effectiveKey = '${storageKey}_$pathSuffix';

    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint/$pathSuffix');
      try {
        final response = await http
            .get(uri, headers: await _getHeaders())
            .timeout(const Duration(seconds: 35));
        await _updateCookie(response);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          await _saveToLocal(data, effectiveKey);
          return data;
        } else {
          final cached = await _fetchOneFromLocal(effectiveKey);
          if (cached != null) return cached;
          final body = jsonDecode(response.body);
          throw (body is Map ? body['error'] : null) ?? 'Fetch error';
        }
      } catch (e) {
        final cached = await _fetchOneFromLocal(effectiveKey);
        if (cached != null) return cached;
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return await _fetchOneFromLocal(effectiveKey) ?? {};
    }
  }

  Future<Map<String, dynamic>?> _fetchOneFromLocal(String effectiveKey) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString(effectiveKey);
    if (dataString != null) {
      return jsonDecode(dataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetch Single Data (GET) - สำหรับ /tasks/:taskId
  Future<Map<String, dynamic>> fetchOne(String id) async {
    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint/$id');
      try {
        final response = await http.get(uri, headers: await _getHeaders());
        await _updateCookie(response);

        if (response.statusCode == 200) {
          print(response.body);
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          throw json.decode(response.body)["error"] ?? "Fetch One Error";
        }
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return {}; // Mock ตามความเหมาะสม
    }
  }

  /// Update Data (PUT) - ปรับแก้ให้ส่งเข้า /tasks ตรงๆ และ ID อยู่ใน Payload ตาม Go Backend
  Future<dynamic> putData(Map<String, dynamic> payload) async {
    if (isRealApi) {
      // ปรับให้ยิงไปที่ endpoint หลัก (เช่น /tasks) ไม่ต้องต่อท้ายด้วย /id
      final uri = Uri.parse('$baseUrl$endpoint');
      try {
        final response = await http.put(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(payload),
        );
        await _updateCookie(response);

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw json.decode(response.body)["error"] ?? "Update Error";
        }
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return payload;
    }
  }

  /// Delete Data (DELETE) - เปลี่ยนเป็นคืนค่า bool เพื่อให้รู้ว่าลบสำเร็จไหม
  Future<bool> deleteData(String identifierValue) async {
    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint/$identifierValue');
      try {
        final response = await http.delete(uri, headers: await _getHeaders());
        await _updateCookie(response);
        return (response.statusCode == 200 || response.statusCode == 204);
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return true;
    }
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ServiceProvider<T> {
  final String storageKey;
  final String endpoint;
  final bool isRealApi;
  final bool useCookie;
  // Overridable at build time via --dart-define=API_BASE_URL=...
  // (e.g. the CI web build points this at the deployed backend).
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mobile-backend-2-t8h6.onrender.com',
  );
  final http.Client _client;

  // เดิมเก็บเป็น "คุกกี้" (อ่านจาก response header set-cookie แล้วส่งกลับเป็น
  // header Cookie: เอง) — วิธีนี้ใช้ไม่ได้บน web build เพราะเบราว์เซอร์ปิดกั้นไม่ให้
  // JS อ่าน set-cookie เลย (ทุกเบราว์เซอร์) และต่อให้อ่านได้ คุกกี้ก็ส่งข้าม origin
  // ไม่ได้อยู่ดี (GitHub Pages เรียก backend คนละโดเมน, ดู mobile-backend's
  // auth_middleware.go) เปลี่ยนมาเก็บ JWT ตรง ๆ จาก field "token" ใน response
  // body แล้วส่งเป็น header Authorization: Bearer แทน — เป็น header ธรรมดา
  // ไม่ติดปัญหา SameSite/third-party-cookie ใด ๆ
  static const String _tokenKey = 'auth_token';

  // APP-2: was plain SharedPreferences (unencrypted on-device storage) for
  // both the session cookie and every cached API response -- backed by the
  // platform keystore/keychain instead (Android EncryptedSharedPreferences,
  // iOS Keychain). One shared instance is fine: flutter_secure_storage
  // handles its own concurrent access internally, same as
  // SharedPreferences.getInstance() did.
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ServiceProvider({
    required this.storageKey,
    required this.endpoint,
    this.isRealApi = false,
    this.useCookie = true,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // --- PRIVATE HELPERS ---

  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<bool> isLoggedIn() async {
    final uri = Uri.parse('$baseUrl/auth/me');
    try {
      // เพิ่ม timeout เพื่อป้องกันกรณีเชื่อมต่อนานเกินไป
      final String? token = await _storage.read(key: _tokenKey);
      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        print('UNAUTHORIZED');
        await logout();
        return false;
      }else if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        final List roles = data['roles'] ?? [];
        if (roles.isEmpty){
          logout();
          return false;
        }
      }
      return token != null && token.isNotEmpty;
    } catch (e) {
      print(e);
      return false;
    }

  }

  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && useCookie) 'Authorization': 'Bearer $token',
    };
  }

  // ตรวจแบบหยาบๆ ว่าหน้าตาเหมือน JWT จริงไหม (3 ส่วนคั่นด้วยจุด ไม่มีส่วนไหนว่าง)
  // ก่อนเก็บ -- endpoint ทั่วไป (ไม่ใช่ auth) ที่บังเอิญมี field ชื่อ "token" อยู่
  // ด้วยเหตุผลอื่น (เช่น pagination cursor, upload token) จะไม่ผ่านเช็คนี้ จึงไม่
  // ไปทับ session token จริงที่ใช้งานได้อยู่แบบเงียบๆ
  bool _looksLikeJwt(String value) {
    final parts = value.split('.');
    return parts.length == 3 && parts.every((p) => p.isNotEmpty);
  }

  // เก็บ session token จาก field "token" ใน response body (ไม่ใช่ header
  // set-cookie อีกต่อไป — ดูคอมเมนต์ที่ _tokenKey) เรียกทุกครั้งหลัง request
  // ไม่ว่า useCookie จะเป็น true/false ก็ตาม (login/register ไม่ได้ "แนบ" token
  // ไปกับ request ขาออก แต่ยังต้องรับ token ที่ตอบกลับมา) — เผื่อ response
  // ไม่ใช่ JSON object (เช่น fetchData คืน list) จึงห่อด้วย try/catch
  //
  // คืนค่า body ที่ decode แล้วกลับไปด้วย (หรือ null ถ้า decode ไม่ได้) เพื่อให้
  // ผู้เรียกใช้ค่านี้ต่อได้เลยแทนที่จะต้อง jsonDecode(response.body) ซ้ำอีกรอบ
  Future<dynamic> _updateToken(http.Response response) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      // response ไม่ใช่ JSON — ไม่มี token ให้เก็บ, ไม่มีอะไรให้คืนกลับ
      return null;
    }
    if (decoded is Map && decoded['token'] is String) {
      final String token = decoded['token'] as String;
      if (token.isNotEmpty && _looksLikeJwt(token)) {
        await _storage.write(key: _tokenKey, value: token);
      }
    }
    return decoded;
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
    await _storage.write(key: effectiveKey, value: jsonEncode(data));
  }

  // 3. ปรับปรุงการดึงจาก Local (รับ key เพิ่ม)
  Future<List<T>> _fetchFromLocal(
    T Function(Map<String, dynamic>) creator,
    String effectiveKey,
  ) async {
    final String? dataString = await _storage.read(key: effectiveKey);
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
        final response = await _client
            .get(uri, headers: await _getHeaders())
            .timeout(const Duration(seconds: 10));

        final decoded = await _updateToken(response);

        if (response.statusCode == 200) {
          final List<dynamic> jsonData = decoded as List<dynamic>;
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
        final response = await _client.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(payload),
        );

        // อัปเดต token จาก Response -- คืนค่า body ที่ decode แล้วกลับมาด้วย
        // เลย ไม่ต้อง jsonDecode(response.body) ซ้ำอีกรอบ (ของเดิม decode 2
        // รอบทั้งที่คอมเมนต์ข้างล่างบอกว่าตั้งใจจะ decode แค่ครั้งเดียว)
        final dynamic responseData = await _updateToken(response);

        // 2. _updateToken decode ไม่ได้ (เช่น Server ล่มแล้วพ่น HTML ออกมา) จะได้
        // null กลับมา -- เดิมเช็คจาก FormatException ตอน jsonDecode ตรงนี้เอง
        // ตอนนี้ decode ไปแล้วใน _updateToken จึงต้องเช็คจากผลลัพธ์แทน (ของจริง
        // ที่ decode ได้เป็น null literal มีโอกาสเกิดน้อยมากและไม่ใช่ response
        // shape ที่ backend endpointไหนใช้).
        if (responseData == null && response.body.trim() != 'null') {
          throw "เซิร์ฟเวอร์ตอบกลับผิดพลาด (Invalid JSON)";
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // ใช้ช่วง 200-299 ครอบคลุมทั้ง OK (200), Created (201), No Content (204)
          print('POST Success: $responseData');
          return responseData;
        } else {
          // 3. ดึง Error Message อย่างปลอดภัย (ป้องกันกรณี responseData ไม่ใช่ Map หรือไม่มี key error)
          String errorMessage = 'Post Error';
          if (responseData is Map && responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData is Map && responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }

          throw errorMessage;
        }
      } catch (e) {
        // 4. จัดการ Error อื่นๆ เช่น No Internet หรือ Timeout
        rethrow;
      }
    } else {
      // Mock Logic: บันทึกลง Local และคืนค่า payload กลับไป
      await _simulateNetworkDelay();
      final String? existingString = await _storage.read(key: storageKey);
      List<dynamic> existingData = existingString != null
          ? jsonDecode(existingString)
          : [];
      existingData.add(payload);
      await _storage.write(key: storageKey, value: jsonEncode(existingData));
      return payload;
    }
  }

  /// Upload one file as multipart/form-data to `endpoint/pathSuffix`, e.g.
  /// /farms/{farmId}/image. Takes bytes rather than a path because the web
  /// build (LIFF) has no file path to read from.
  Future<dynamic> uploadFile(
    String pathSuffix, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint/$pathSuffix'));
    final String? token = await _storage.read(key: _tokenKey);
    request.headers['Accept'] = 'application/json';
    if (token != null && useCookie) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));

    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final decoded = await _updateToken(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw (decoded is Map ? decoded['error'] : null) ?? 'Upload Error (${response.statusCode})';
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
        final response = await _client
            .get(uri, headers: await _getHeaders())
            .timeout(const Duration(seconds: 35));
        final decoded = await _updateToken(response);

        if (response.statusCode == 200) {
          final data = decoded as Map<String, dynamic>;
          await _saveToLocal(data, effectiveKey);
          return data;
        } else {
          final cached = await _fetchOneFromLocal(effectiveKey);
          if (cached != null) return cached;
          throw (decoded is Map ? decoded['error'] : null) ?? 'Fetch error';
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
    final String? dataString = await _storage.read(key: effectiveKey);
    if (dataString != null) {
      return jsonDecode(dataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Fetch Single Data (GET) at the endpoint's own path, e.g. /auth/me --
  /// unlike fetchOne(id), nothing is appended after `endpoint`, so this
  /// never produces a trailing-slash URL for endpoints with no id segment.
  Future<Map<String, dynamic>> fetchSelf() async {
    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint');
      try {
        // RootScaffold leaves _isLoading true until this future settles,
        // and while it is true the whole screen is a bare spinner -- no
        // nav bar, no retry. A connection that stalls without erroring
        // (weak signal out on a farm) would hang the app until force
        // quit, so this has to fail rather than wait. Same 10s as
        // isLoggedIn() and fetchAll().
        final response = await _client
            .get(uri, headers: await _getHeaders())
            .timeout(const Duration(seconds: 10));
        final decoded = await _updateToken(response);

        if (response.statusCode == 200) {
          // _updateToken returns null when the body is not JSON at all, so
          // a bare cast would throw an opaque TypeError here -- and
          // RootScaffold's catch swallows it, leaving the same silently
          // empty profile page this endpoint was just fixed to stop
          // producing. Fail with something readable instead.
          if (decoded is! Map<String, dynamic>) {
            throw "รูปแบบข้อมูลโปรไฟล์ไม่ถูกต้อง";
          }
          return decoded;
        } else {
          throw (decoded is Map ? decoded['error'] : null) ?? "Fetch Self Error";
        }
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return {};
    }
  }

  /// Fetch Single Data (GET) - สำหรับ /tasks/:taskId
  Future<Map<String, dynamic>> fetchOne(String id) async {
    if (isRealApi) {
      final uri = Uri.parse('$baseUrl$endpoint/$id');
      try {
        final response = await _client.get(uri, headers: await _getHeaders());
        final decoded = await _updateToken(response);

        if (response.statusCode == 200) {
          print(response.body);
          return decoded as Map<String, dynamic>;
        } else {
          throw (decoded is Map ? decoded['error'] : null) ?? "Fetch One Error";
        }
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return {}; // Mock ตามความเหมาะสม
    }
  }

  /// GET one object that may legitimately not exist -- returns null for any
  /// non-200 (204 "nothing to offer", 404, 5xx) instead of throwing the way
  /// fetchOne does. Same headers and token handling as every other call
  /// here. Deliberately NOT cached: it is for answers that only make sense
  /// fresh from the server (autofill), where a stale offline copy would be
  /// worse than none. Network failure / timeout still throws, so the caller
  /// decides what offline means for it.
  Future<Map<String, dynamic>?> fetchOneOptional(
    String pathSuffix, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isRealApi) return null;
    final uri = Uri.parse('$baseUrl$endpoint/$pathSuffix');
    final response = await _client
        .get(uri, headers: await _getHeaders())
        .timeout(timeout);
    final decoded = await _updateToken(response);
    if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  /// Update Data (PUT) - ปรับแก้ให้ส่งเข้า /tasks ตรงๆ และ ID อยู่ใน Payload ตาม Go Backend
  Future<dynamic> putData(Map<String, dynamic> payload) async {
    if (isRealApi) {
      // ปรับให้ยิงไปที่ endpoint หลัก (เช่น /tasks) ไม่ต้องต่อท้ายด้วย /id
      final uri = Uri.parse('$baseUrl$endpoint');
      try {
        final response = await _client.put(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode(payload),
        );
        final decoded = await _updateToken(response);

        if (response.statusCode == 200) {
          return decoded;
        } else {
          throw (decoded is Map ? decoded['error'] : null) ?? "Update Error";
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
        final response = await _client.delete(uri, headers: await _getHeaders());
        await _updateToken(response);
        return (response.statusCode == 200 || response.statusCode == 204);
      } catch (e) {
        rethrow;
      }
    } else {
      await _simulateNetworkDelay();
      return true;
    }
  }

  /// Overwrite the local list under [storageKey] in one write -- for the
  /// offline queue, which removes individual items by rebuilding the list
  /// (deleteData is a no-op in local mode, so it can't remove anything).
  Future<void> replaceLocal(List<Map<String, dynamic>> items) async {
    await _storage.write(key: storageKey, value: jsonEncode(items));
  }

  Future<void> deleteAll() async {
    await _storage.delete(key: storageKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}

import 'package:cocoa_supply/models/profile_model.dart';
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client})
    : _provider = ServiceProvider<Profile>(
        storageKey: 'user_profile_data',
        endpoint: ApiEndpoints.me,
        isRealApi: true,
        client: client,
      ),
      _places = ServiceProvider<Map<String, dynamic>>(
        storageKey: 'constants_location',
        endpoint: ApiEndpoints.constants('location'),
        isRealApi: true,
        client: client,
      );

  // ใช้ ServiceProvider พื้นฐานเหมือนเดิม
  final ServiceProvider<Profile> _provider;
  final ServiceProvider<Map<String, dynamic>> _places;

  /// ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์ทั้งหมด (ใช้ในหน้า Profile)
  Future<Profile?> getProfile() async {
    try {
      final Map<String, dynamic> result = await _provider.fetchSelf();
      print(result);
      return _withPlaceNames(Profile.fromJson(result));
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
  }

  /// GET /me gives the subdistrict's id only (mobile-backend's /auth/me also
  /// sent the names), so the names come from the location list. If that
  /// lookup fails the profile still shows, without them.
  Future<Profile> _withPlaceNames(Profile profile) async {
    final id = profile.subdistrictId;
    if (id == null || id.isEmpty || profile.subdistrictName != null) return profile;
    try {
      final rows = await _places.fetchData((json) => json, queryParams: {'subdistrict_id': id});
      if (rows.isEmpty) return profile;
      final place = rows.first;
      return profile.withPlaceNames(
        subdistrictName: place['subdistrict_name']?.toString(),
        districtName: place['district_name']?.toString(),
        provinceName: place['province_name']?.toString(),
      );
    } catch (_) {
      return profile;
    }
  }

  /// แถม: ฟังก์ชันสำหรับ Clear Cache ตอน Logout
  Future<void> logout() async {
    // DynamicApiService caches province/district/subdistrict in a static
    // map that would otherwise survive into the next account's session.
    DynamicApiService.clearConstantsCache();
  }
}

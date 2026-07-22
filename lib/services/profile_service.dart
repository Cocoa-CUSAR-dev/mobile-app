import 'package:cocoa_supply/models/profile_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class AuthService {
  // ใช้ ServiceProvider พื้นฐานเหมือนเดิม
  final ServiceProvider<Profile> _provider = ServiceProvider<Profile>(
    storageKey: 'user_profile_data',
    endpoint: '/auth/me',
    isRealApi: true
  );

  /// ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์ทั้งหมด (ใช้ในหน้า Profile)
  Future<Profile?> getProfile() async {
    try {
      // เรียก fetchData ซึ่งจะได้ List กลับมา
      final Map<String, dynamic> result = await _provider.fetchOne('');
      print(result);
      if(result != null){
        return Profile.fromJson(result);
      }
      return null;
    } catch (e) {
      print('Error in getProfile: $e');
      rethrow;
    }
  }

  /// แถม: ฟังก์ชันสำหรับ Clear Cache ตอน Logout
  Future<void> logout() async {
   
  }
}
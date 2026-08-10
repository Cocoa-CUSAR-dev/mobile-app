import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';

/// key ใน SharedPreferences ที่บันทึกไว้ว่าผู้ใช้เปิดหน้าสมัครสมาชิกนี้มาจาก
/// ปุ่ม "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing (liff.openWindow ?from=liff)
/// เพื่อให้ RegisterRolePage รู้ว่าต้อง redirect กลับเข้า LINE หลังลงทะเบียนสำเร็จ
const liffRegistrationFlagKey = 'liff_registration_pending';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({super.key});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _registerService = ServiceProvider<dynamic>(
    endpoint: '/public/register',
    storageKey: 'user_register',
    isRealApi: true,
    useCookie: false,
  );

  final Map<String, TextEditingController> _controllers = {
    'username': TextEditingController(),
    'password': TextEditingController(),
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'phoneNumber': TextEditingController(),
    'email': TextEditingController(),
    'addressDetail': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markLiffOriginIfNeeded();
  }

  Future<void> _markLiffOriginIfNeeded() async {
    if (Uri.base.queryParameters['from'] == 'liff') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(liffRegistrationFlagKey, true);
    }
  }

  // --- Validation Logic (Regex) ---
  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'กรุณาระบุเบอร์โทรศัพท์';
    // เช็คตัวเลข 10 หลัก ขึ้นต้นด้วย 0
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v))
      return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก (เช่น 08XXXXXXXX)';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = _controllers.map(
        (key, controller) => MapEntry(key, controller.text.trim()),
      );

      // // เพิ่มพิกัดเข้าไปใน Payload
      // payload['latitude'] = _selectedLocation!.latitude.toString();
      // payload['longitude'] = _selectedLocation!.longitude.toString();

      await _registerService.postData(payload);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(
          content: Text('ลงทะเบียนสำเร็จ ครั้งถัดไปกรุณาเลือก มีบัญชีผู้ใช้แล้ว'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pushNamed(context, AppRoute.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ลงทะเบียนไม่สำเร็จ: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ลงทะเบียนผู้ใช้งานใหม่',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF794c46),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'กรุณากรอกข้อมูลเพื่อเข้าใช้งานระบบ',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),

              // เบอร์โทรศัพท์พร้อม Validation ใหม่
              FormInput(
                label: 'เบอร์โทรศัพท์',
                hintText: 'เช่น 08XXXXXXXX',
                controller: _controllers['username']!,
                isRequired: true,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              // รหัสผ่าน
              FormInput(
                label: 'รหัสผ่าน',
                hintText: 'กำหนดรหัสผ่าน 8 หลักขึ้นไป',
                controller: _controllers['password']!,
                isPassword: true,
                isRequired: true,
                validator: (v) =>
                    v!.length < 8 ? 'รหัสผ่านต้องมี 8 ตัวขึ้นไป' : null,
              ),
              // อีเมลพร้อม Validation
              FormInput(
                label: 'อีเมล',
                hintText: 'example@email.com',
                controller: _controllers['email']!,
                keyboardType: TextInputType.emailAddress,
                //validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF794c46),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ยืนยันการลงทะเบียน',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

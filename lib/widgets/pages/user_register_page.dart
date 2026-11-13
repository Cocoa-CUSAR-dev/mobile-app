import 'package:flutter/material.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/email_validation.dart';
import 'package:cocoa_supply/services/role_registration.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/app_snackbar.dart';

/// The shortest password backend-hub accepts at sign-up.
const int minPasswordLength = 6;

/// Sign-up, the first step (docs-and-plan#320): phone, password typed twice,
/// and an optional email. The role form comes next and starts with this
/// phone number filled in, so it isn't asked again.
class UserRegisterPage extends StatefulWidget {
  /// true = มาจากปุ่ม "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing — สมัครเสร็จแล้วให้
  /// ไปฟอร์ม login/link ของ LiffLinkPage ต่อเลย (เชื่อมบัญชี LINE อัตโนมัติ) แทน
  /// หน้า login ปกติ
  final bool fromLiff;

  const UserRegisterPage({super.key, this.fromLiff = false});

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _registerService = ServiceProvider<dynamic>(
    endpoint: ApiEndpoints.authRegister,
    storageKey: 'user_register',
    isRealApi: true,
    useCookie: false,
  );

  // What backend-hub's register takes (email is optional); name, phone and
  // address belong to each role's profile and are asked on the next page.
  final Map<String, TextEditingController> _controllers = {
    'username': TextEditingController(),
    'password': TextEditingController(),
    'email': TextEditingController(),
  };
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;

  /// After the first try, every field re-checks itself as it changes, so a
  /// fixed mistake stops showing its message.
  bool _triedSubmit = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  String get _password => _controllers['password']!.text;

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'กรุณาระบุเบอร์โทรศัพท์';
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v)) {
      return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก (เช่น 08XXXXXXXX)';
    }
    return null;
  }

  String? _validatePassword(String? v) =>
      (v ?? '').length < minPasswordLength ? 'รหัสผ่านต้องมี $minPasswordLength ตัวขึ้นไป' : null;

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่านอีกครั้ง';
    return v == _password ? null : 'รหัสผ่านไม่ตรงกัน';
  }

  Future<void> _handleRegister() async {
    if (!_triedSubmit) setState(() => _triedSubmit = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = _controllers.map((key, controller) => MapEntry(key, controller.text.trim()));
      if (payload['email']!.isEmpty) payload.remove('email');

      // The hub signs the new account in: its answer is a token pair, which
      // postData keeps. So no second login -- straight on to picking a role.
      await _registerService.postData(payload);

      if (mounted) {
        AppSnackBar.show(context, 'สร้างบัญชีเรียบร้อย', type: AppSnackBarType.success);
        if (widget.fromLiff) {
          // สมัครมาจากหน้า LIFF landing — ไป LiffLinkPage ต่อเลย พร้อมบัญชีที่เพิ่ง
          // สมัคร เพื่อเชื่อมบัญชี LINE ให้อัตโนมัติโดยไม่ต้องกรอกรหัสผ่านซ้ำ
          Navigator.of(context).pushNamed(
            AppRoute.liffLink,
            arguments: {'postRegistration': true, 'username': payload['username'], 'password': payload['password']},
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoute.roleRegister,
            (route) => false,
            arguments: {'prefill': signUpPrefill(payload['username'])},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // The hub's own Thai message (e.g. the username is taken) when it
        // refused; a generic one for no connection.
        final message = e is ServerRejection ? e.message : 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่';
        AppSnackBar.show(context, 'ลงทะเบียนไม่สำเร็จ: $message', type: AppSnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _eye(bool shown, VoidCallback toggle) => IconButton(
    icon: Icon(shown ? Icons.visibility : Icons.visibility_off),
    tooltip: shown ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
    onPressed: toggle,
  );

  /// A line under a password field: green with a tick once it holds, red
  /// when [broken] (the two passwords differ), grey until then.
  Widget _rule(String text, bool met, {bool broken = false}) {
    final color = met
        ? Colors.green.shade700
        : broken
        ? Colors.red.shade700
        : Colors.grey.shade600;
    final icon = met
        ? Icons.check_circle
        : broken
        ? Icons.error_outline
        : Icons.radio_button_unchecked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirm = _confirmController.text;
    final textTheme = Theme.of(context).textTheme;
    return SimpleScaffold(
      title: '',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _triedSubmit ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('สร้างบัญชี', style: textTheme.headlineSmall?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              Text(
                'ขั้นต่อไปจะให้เลือกบทบาทและกรอกข้อมูล',
                style: textTheme.bodyLarge?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              FormInput(
                label: 'เบอร์โทรศัพท์',
                hintText: 'เช่น 08XXXXXXXX',
                controller: _controllers['username']!,
                isRequired: true,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                validator: _validatePhone,
              ),
              FormInput(
                label: 'รหัสผ่าน',
                hintText: 'ตั้งรหัสผ่านของคุณ',
                controller: _controllers['password']!,
                isPassword: !_showPassword,
                isRequired: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: _eye(_showPassword, () => setState(() => _showPassword = !_showPassword)),
                onChanged: (_) => setState(() {}),
                validator: _validatePassword,
              ),
              _rule('อย่างน้อย $minPasswordLength ตัว', _password.length >= minPasswordLength),
              FormInput(
                label: 'ยืนยันรหัสผ่าน',
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
                controller: _confirmController,
                isPassword: !_showConfirm,
                isRequired: true,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: _eye(_showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                onChanged: (_) => setState(() {}),
                validator: _validateConfirm,
              ),
              if (confirm.isNotEmpty)
                confirm == _password ? _rule('รหัสผ่านตรงกัน', true) : _rule('รหัสผ่านไม่ตรงกัน', false, broken: true),
              FormInput(
                label: 'อีเมล (ไม่บังคับ)',
                hintText: 'ใช้เข้าสู่ระบบแทนเบอร์โทรได้',
                controller: _controllers['email']!,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline, color: AppColors.primary),
                validator: emailError,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('ถัดไป: เลือกบทบาท', style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('มีบัญชีแล้ว?', style: textTheme.bodyLarge),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

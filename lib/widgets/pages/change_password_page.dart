import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// The first sign-in after an admin handed over a temporary password
/// (must_reset_password): pick your own before going on.
///
/// There is no way past this screen except a new password, and no back button,
/// because the temporary password is known to someone else.
class ChangePasswordPage extends StatefulWidget {
  final http.Client? client;

  const ChangePasswordPage({super.key, this.client});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const int minPasswordLength = 6;

  late final ServiceProvider _service = ServiceProvider(
    storageKey: 'password',
    endpoint: ApiEndpoints.authResetPassword,
    isRealApi: true,
    client: widget.client,
  );
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _problem() {
    if (_password.text.length < minPasswordLength) return 'รหัสผ่านต้องมีอย่างน้อย $minPasswordLength ตัวอักษร';
    if (_password.text != _confirm.text) return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
    return null;
  }

  Future<void> _submit() async {
    final problem = _problem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The answer is a new token pair, which ServiceProvider keeps: the old
      // sessions of this account have just ended.
      final response = await _service.patchData({'new_password': _password.text});
      if (!mounted) return;
      final Object? user = response is Map ? response['user'] : null;
      final Object? roles = user is Map ? user['roles'] : null;
      final hasRole = roles is List && roles.isNotEmpty;
      Navigator.of(context).pushReplacementNamed(hasRole ? AppRoute.home : AppRoute.roleRegister);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('ตั้งรหัสผ่านใหม่'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'คุณเข้าสู่ระบบด้วยรหัสผ่านชั่วคราว กรุณาตั้งรหัสผ่านของคุณเองก่อนใช้งานต่อ',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 24),
                FormInput(
                  label: 'รหัสผ่านใหม่',
                  controller: _password,
                  isPassword: !_showPassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                FormInput(
                  label: 'ยืนยันรหัสผ่านใหม่',
                  controller: _confirm,
                  isPassword: !_showPassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_error!, style: text.bodyMedium?.copyWith(color: Colors.red)),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'บันทึกรหัสผ่านใหม่',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

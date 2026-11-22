import 'dart:async';

import 'package:cocoa_supply/services/password_reset_service.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/app_snackbar.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Forgot password, in two steps: ask for a code (sent to the email or LINE on
/// the account), then enter the code with a new password.
///
/// The first step answers the same whether or not the account exists, so this
/// screen says only that a code is on its way "if there is one to send to".
class ForgotPasswordPage extends StatefulWidget {
  /// What was typed on the login page, to save typing it again.
  final String initialLogin;
  final http.Client? client;

  /// Seconds before a new code can be asked for.
  final int resendSeconds;

  const ForgotPasswordPage({super.key, this.initialLogin = '', this.client, this.resendSeconds = 60});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const int minPasswordLength = 6;

  late final PasswordResetService _service = PasswordResetService(client: widget.client);
  late final TextEditingController _login = TextEditingController(text: widget.initialLogin);
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _codeStep = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _login.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft = _secondsLeft - 1);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _askForCode() async {
    if (_login.text.trim().isEmpty) {
      setState(() => _error = 'กรุณากรอกเบอร์มือถือหรืออีเมล');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.requestCode(_login.text);
      if (!mounted) return;
      setState(() => _codeStep = true);
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final problem = _passwordProblem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.confirm(login: _login.text, code: _code.text, newPassword: _password.text);
      if (!mounted) return;
      AppSnackBar.show(context, 'เปลี่ยนรหัสผ่านแล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่', type: AppSnackBarType.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _passwordProblem() {
    if (_code.text.trim().isEmpty) return 'กรุณากรอกรหัส 6 หลักที่ได้รับ';
    if (_password.text.length < minPasswordLength) return 'รหัสผ่านต้องมีอย่างน้อย $minPasswordLength ตัวอักษร';
    if (_password.text != _confirm.text) return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('ลืมรหัสผ่าน'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _codeStep ? _codeStepWidgets(text) : _askStepWidgets(text),
          ),
        ),
      ),
    );
  }

  List<Widget> _askStepWidgets(TextTheme text) => [
    Text('กรอกเบอร์มือถือหรืออีเมลที่ใช้เข้าสู่ระบบ เราจะส่งรหัส 6 หลักไปให้', style: text.bodyLarge),
    const SizedBox(height: 24),
    FormInput(
      label: 'เบอร์มือถือหรืออีเมล',
      controller: _login,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
    ),
    ..._errorWidget(text),
    const SizedBox(height: 8),
    _button('ส่งรหัส', _busy ? null : _askForCode),
    const SizedBox(height: 16),
    Text(
      'บัญชีที่ไม่มีอีเมลหรือไม่ได้เชื่อมต่อ LINE จะไม่ได้รับรหัส ให้ติดต่อผู้ดูแลเพื่อขอรีเซ็ตรหัสผ่าน',
      style: text.bodyMedium?.copyWith(color: Colors.black54),
    ),
  ];

  List<Widget> _codeStepWidgets(TextTheme text) => [
    Text(
      'ถ้าบัญชีนี้มีอีเมลหรือเชื่อมต่อ LINE ไว้ เราส่งรหัส 6 หลักไปให้แล้ว รหัสใช้ได้ 15 นาที',
      style: text.bodyLarge,
    ),
    const SizedBox(height: 24),
    FormInput(
      label: 'รหัส 6 หลัก',
      controller: _code,
      keyboardType: TextInputType.number,
      prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
    ),
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
    ..._errorWidget(text),
    const SizedBox(height: 8),
    _button('เปลี่ยนรหัสผ่าน', _busy ? null : _changePassword),
    const SizedBox(height: 8),
    TextButton(
      onPressed: (_busy || _secondsLeft > 0) ? null : _askForCode,
      child: Text(_secondsLeft > 0 ? 'ขอรหัสใหม่ได้ใน $_secondsLeft วินาที' : 'ขอรหัสใหม่'),
    ),
    const SizedBox(height: 8),
    Text(
      'ถ้าไม่ได้รับรหัส ให้ติดต่อผู้ดูแลเพื่อขอรีเซ็ต',
      textAlign: TextAlign.center,
      style: text.bodyMedium?.copyWith(color: Colors.black54),
    ),
  ];

  List<Widget> _errorWidget(TextTheme text) => [
    if (_error != null)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_error!, style: text.bodyMedium?.copyWith(color: Colors.red)),
      ),
  ];

  Widget _button(String label, VoidCallback? onPressed) => ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: _busy
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
  );
}

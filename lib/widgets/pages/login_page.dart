import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/role_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/app_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  String? _errorMessage;

  // โทนสีตามธีมเดิม
  final Color primaryColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    context.read<LoginBloc>().add(LoadLogin());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _errorMessage = null);

  void _onLogin() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน');
    } else {
      context.read<LoginBloc>().add(
        LoginButtonPressed(username: _usernameController.text, password: _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // --- พื้นหลังเดิม (Positioned + Image.asset) ---
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/images/bg.png',
              width: MediaQuery.of(context).size.width * 1.2,
              fit: BoxFit.cover,
            ),
          ),

          BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state is LoginSuccess) {
                if (state.next_page == "HOME") {
                  Navigator.of(context).pushReplacementNamed(AppRoute.home);
                } else {
                  // No role yet: the role form starts with the phone number
                  // they just signed in with.
                  Navigator.of(context).pushReplacementNamed(
                    AppRoute.roleRegister,
                    arguments: {'prefill': signUpPrefill(_usernameController.text)},
                  );
                }
              } else if (state is LoginFailure) {
                AppSnackBar.show(context, state.error, type: AppSnackBarType.error);
              }
            },
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    // --- ส่วนหัว (Logo & Welcome) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยินดีต้อนรับเข้าสู่แอปพลิเคชัน',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Image.asset('assets/images/logo.png', width: 280),
                      ],
                    ),
                    const SizedBox(height: 50),

                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ส่วนฟอร์ม Login
  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey(2),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('เข้าสู่ระบบ', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 24),
            FormInput(
              label: 'เบอร์มือถือหรืออีเมล',
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
            FormInput(
              label: 'รหัสผ่าน',
              controller: _passwordController,
              isPassword: !_isPasswordVisible,
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_errorMessage!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            BlocBuilder<LoginBloc, LoginState>(
              builder: (context, state) {
                final isLoading = state is LoginLoading;
                return _buildMainButton(
                  label: 'ลงชื่อเข้าใช้งาน',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: isLoading ? null : _onLogin,
                  backgroundColor: primaryColor,
                  textColor: Colors.white,
                  isLoading: isLoading,
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('ยังไม่มีบัญชี?', style: Theme.of(context).textTheme.bodyLarge),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoute.userRegister),
                  child: Text(
                    'สมัครใช้งาน',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ปุ่มสไตล์ใหม่ที่ดูพรีเมียมขึ้น ---

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(color: backgroundColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon, color: textColor, size: 22),
        label: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

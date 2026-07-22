import 'package:cocoa_supply/route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_bloc.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showLoginForm = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  // โทนสีตามธีมเดิม
  final Color primaryColor = const Color(0xFF794c46);

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
            LoginButtonPressed(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
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
                Navigator.of(context).pushReplacementNamed(
                  state.next_page == "HOME" ? AppRoute.home : AppRoute.roleRegister,
                );
              } else if (state is LoginFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
                        const Text(
                          'ยินดีต้อนรับเข้าสู่แอปพลิเคชัน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Image.asset('assets/images/logo.png', width: 280),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // --- เนื้อหาที่มี Animation สลับไปมา ---
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLoginForm ? _buildLoginForm() : _buildSelectionArea(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ส่วนเลือก (มีบัญชี / ไม่มีบัญชี)
  Widget _buildSelectionArea() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ท่านมีบัญชีผู้ใช้อยู่แล้วหรือไม่',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        _buildMainButton(
          label: 'มีบัญชีผู้ใช้แล้ว',
          icon: Icons.login_rounded,
          onPressed: () => setState(() => _showLoginForm = true),
          backgroundColor: primaryColor,
          textColor: Colors.white,
        ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          label: 'ยังไม่มีบัญชีผู้ใช้',
          onPressed: () => Navigator.of(context).pushNamed(AppRoute.userRegister),
        ),
      ],
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
            FormInput(
              label: 'เบอร์มือถือ',
              controller: _usernameController,
            ),
            FormInput(
              label: 'รหัสผ่าน',
              controller: _passwordController,
              isPassword: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
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
            _buildSecondaryButton(
              label: 'ย้อนกลับ',
              onPressed: () => setState(() => _showLoginForm = false),
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
            BoxShadow(
              color: backgroundColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon, color: textColor, size: 22),
        label: isLoading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
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

  Widget _buildSecondaryButton({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
      ),
    );
  }
}
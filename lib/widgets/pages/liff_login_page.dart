import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';

/// หน้าเชื่อมบัญชีเดิมกับ LINE ผ่าน LIFF — เข้าถึงได้ทาง route '/liff-link' เท่านั้น
/// (ตั้งเป็น LIFF Endpoint URL ใน LINE Developers Console)
/// ต่างจาก LoginPage ตรงที่ต้องเรียก liff.init() ก่อน ซึ่งหน้า web ปกติเรียกไม่ได้/ไม่ควรเรียก
class LiffLinkPage extends StatefulWidget {
  const LiffLinkPage({super.key});

  @override
  State<LiffLinkPage> createState() => _LiffLinkPageState();
}

class _LiffLinkPageState extends State<LiffLinkPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final Color primaryColor = const Color(0xFF794c46);

  @override
  void initState() {
    super.initState();
    context.read<LiffLoginBloc>().add(LiffInitRequested());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    context.read<LiffLoginBloc>().add(
          LiffLoginSubmitted(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              const Text(
                'เชื่อมบัญชีเดิมกับ LINE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              BlocConsumer<LiffLoginBloc, LiffLoginState>(
                listener: (context, state) {
                  if (state is LiffLoginFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LiffLoginInitial || state is LiffInitializing) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is LiffLoginSuccess) {
                    return _buildSuccess(state);
                  }

                  // LiffLoginFailure ที่ไม่มี idToken เลย = liff.init() ล้มเหลวเอง
                  // (เช่น scope openid ไม่ครบ, LIFF_ID ผิด) ไม่มี idToken ให้กรอก
                  // ฟอร์มไปส่งต่อได้เลย ต้องโชว์ error แทนฟอร์ม ไม่ใช่ปล่อยให้
                  // กรอกแล้วไปพังตอน submit แบบงงๆ
                  if (state is LiffLoginFailure && state.idToken == null) {
                    return _buildInitError(state);
                  }

                  // LiffReady / LiffLoginLoading / LiffLoginFailure ที่มี idToken
                  // (submit ไม่ผ่านแต่เคยได้ idToken มาแล้ว) — โชว์ฟอร์ม
                  final isLoading = state is LiffLoginLoading;
                  return Form(
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
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'เชื่อมบัญชีกับ LINE',
                                  style: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitError(LiffLoginFailure state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '❌ เชื่อมต่อกับ LINE ไม่สำเร็จ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
          ),
          const SizedBox(height: 8),
          Text(state.error, style: TextStyle(color: Colors.red.shade900)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.read<LiffLoginBloc>().add(LiffInitRequested()),
            child: const Text('ลองใหม่อีกครั้ง'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(LiffLoginSuccess state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✅ ${state.message}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('user_id: ${state.userId}'),
          Text('line_user_id: ${state.lineUserId}'),
        ],
      ),
    );
  }
}

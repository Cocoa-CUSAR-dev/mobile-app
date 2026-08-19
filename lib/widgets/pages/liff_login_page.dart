import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';

/// หน้าเชื่อมบัญชีเดิมกับ LINE ผ่าน LIFF — เข้าถึงได้ทาง route '/liff-link' เท่านั้น
/// (ตั้งเป็น LIFF Endpoint URL ใน LINE Developers Console)
/// ต่างจาก LoginPage ตรงที่ต้องเรียก liff.init() ก่อน ซึ่งหน้า web ปกติเรียกไม่ได้/ไม่ควรเรียก
class LiffLinkPage extends StatefulWidget {
  /// true = มาจาก flow "ยังไม่มีบัญชีผู้ใช้" ที่เพิ่งสมัครสมาชิกเสร็จ (UserRegisterPage)
  /// ข้ามหน้า landing ไปฟอร์ม login ตรงๆ เลย — สิ่งที่เกิดขึ้นหลัง login สำเร็จ
  /// (ไปกรอกโปรไฟล์ต่อ หรือผูกบัญชี LINE เลย) เหมือนกันทั้งสอง flow เพราะเช็คจาก
  /// has_profile ที่ backend ส่งกลับมา ไม่ได้แยกตาม flag นี้ (ดู listener ใน
  /// build() ด้านล่าง)
  final bool postRegistration;

  const LiffLinkPage({super.key, this.postRegistration = false});

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
    // postRegistration: liff.init() วิ่งไปแล้วครั้งแรกที่เข้าหน้านี้ตอนต้น session
    // (LiffLoginBloc เป็น instance เดียวทั้งแอป ไม่ได้ผูกกับ widget นี้) ข้ามหน้า
    // landing ไปเรียก LiffHasAccountPressed ตรงๆ เพื่อขอ idToken + โชว์ฟอร์ม login เลย
    context.read<LiffLoginBloc>().add(
          widget.postRegistration ? LiffHasAccountPressed() : LiffInitRequested(),
        );
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
              BlocBuilder<LiffLoginBloc, LiffLoginState>(
                builder: (context, state) {
                  final title = state is LiffLanding
                      ? 'ยินดีต้อนรับ'
                      : 'เชื่อมบัญชีเดิมกับ LINE';
                  return Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                },
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
                  if (state is LiffLoggedIn) {
                    // login สำเร็จ (ยังไม่ได้ผูกบัญชี LINE) — เช็ค has_profile
                    // จาก backend (เหมือน next_page ของ Login ปกติ) ว่ามีโปรไฟล์
                    // (role) แล้วหรือยัง:
                    // - ยังไม่มี → ไปกรอกที่ RegisterRolePage ก่อน (ผูกบัญชี LINE
                    //   ทีหลัง หลังกรอกโปรไฟล์เสร็จ — ดู register_role_page.dart)
                    // - มีแล้ว → ผูกบัญชี LINE ต่อได้เลย (LiffLinkRequested) แล้ว
                    //   ไปหน้าแสดงผลการผูกบัญชี (LiffAccountLinkPage)
                    if (state.hasProfile) {
                      context.read<LiffLoginBloc>().add(
                            LiffLinkRequested(idToken: state.idToken),
                          );
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoute.liffAccountLink,
                        (route) => false,
                      );
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoute.roleRegister,
                        (route) => false,
                        arguments: {'fromLiff': true, 'idToken': state.idToken},
                      );
                    }
                  }
                },
                builder: (context, state) {
                  if (state is LiffLoginInitial ||
                      state is LiffInitializing ||
                      state is LiffLoggedIn) {
                    // LiffLoggedIn เป็นสถานะผ่านทาง — listener ด้านบนพาไปหน้า
                    // ถัดไปทันที โชว์แค่ spinner สั้นๆ ระหว่างรอ navigate
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is LiffLanding) {
                    return _buildLanding(context);
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

  // เดิมตั้งใจใช้ liffOpenWindow() สลับไป browser ปกตินอก LIFF แต่ทดสอบบนเครื่องจริง
  // (Android, isInClient=true) แล้วพบว่า liff.openWindow() ทั้ง external:true และ
  // false return โดยไม่ throw แต่ไม่ทำอะไรจริงเลย (native bridge เงียบ ไม่รองรับบน
  // LINE version/Android build นี้) — เปลี่ยนมา navigate แบบ in-app ภายใน LIFF
  // webview เดิมแทน ซึ่งไม่ต้องพึ่ง native bridge ใดๆ เลยจึงชัวร์กว่า ปลอดภัยเพราะ
  // UserRegisterPage/RegisterRolePage ในสเต็ปนี้ไม่มี MapLibre/file upload
  void _onNoAccountPressed(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoute.userRegister,
      arguments: {'fromLiff': true},
    );
  }

  Widget _buildLanding(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ท่านมีบัญชีผู้ใช้อยู่แล้วหรือไม่',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () =>
              context.read<LiffLoginBloc>().add(LiffHasAccountPressed()),
          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 22),
          label: const Text(
            'มีบัญชีผู้ใช้แล้ว',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _onNoAccountPressed(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
          ),
          child: const Text(
            'ยังไม่มีบัญชีผู้ใช้',
            style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
            onPressed: () => context.read<LiffLoginBloc>().add(
                  widget.postRegistration ? LiffHasAccountPressed() : LiffInitRequested(),
                ),
            child: const Text('ลองใหม่อีกครั้ง'),
          ),
        ],
      ),
    );
  }

}

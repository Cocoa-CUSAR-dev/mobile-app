import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/services/liff_service.dart';
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

  // TODO(debug): log บนหน้าจอชั่วคราวสำหรับ diagnose ปุ่ม "ยังไม่มีบัญชีผู้ใช้"
  // ที่กดแล้วไม่มีอะไรเกิดขึ้นตอนทดสอบใน LINE webview จริง (เข้า chrome://inspect
  // ไม่ได้เพราะ LINE ไม่เปิด WebView debugging) — ลบออกได้เมื่อหาสาเหตุเจอแล้ว
  final List<String> _debugLog = [];

  void _log(String msg) {
    debugPrint('[LiffLinkPage] $msg');
    if (mounted) setState(() => _debugLog.add(msg));
  }

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
                  if (state is LiffLoginSuccess) {
                    // โชว์ข้อความสำเร็จค้างไว้ 3 วินาที แล้วปิดหน้าจอ LIFF
                    // กลับไปที่ช่องแชท LINE ให้เอง — ไม่ต้องรอ user กดปิดเอง
                    Future.delayed(const Duration(seconds: 3), () {
                      liffCloseWindow();
                    });
                  }
                },
                builder: (context, state) {
                  if (state is LiffLoginInitial || state is LiffInitializing) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is LiffLanding) {
                    return _buildLanding(context);
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

  // เรียก liffOpenWindow() ตรงๆ แบบ sync จาก onPressed เลย ห้ามผ่าน bloc event —
  // เพราะ Bloc.add() ประมวลผลผ่าน Stream แบบ async (มี microtask คั่นเสมอ) ทำให้
  // เมื่อ liff.openWindow() เรียก window.open() จริงตอนนั้น browser ปกติจะมองว่า
  // ไม่ได้เกิดจาก user gesture โดยตรงแล้ว แล้วเงียบๆ บล็อกเป็น popup (ไม่มี error
  // โผล่ให้เห็นเลย ปุ่มเหมือนกดไม่ติด — เจอเคสนี้ตอนทดสอบบน external browser)
  //
  // ในแอป LINE จริง (isInClient) พังคนละสาเหตุ: liff.openWindow(external:true)
  // อาจ throw/ไม่ทำงานเงียบๆ ตาม LINE app version หรือ platform ที่ไม่รองรับการ
  // สลับไป external browser จาก LIFF view นี้ — จับ error โชว์ SnackBar ให้เห็น
  // จริงว่าเกิดอะไรขึ้น แทนที่จะปล่อยให้ปุ่มดูเหมือนกดไม่ติดแบบก่อนหน้า แล้ว fallback
  // ไปเปิดใน in-app browser แทน (external:false) — หน้า UserRegisterPage/
  // RegisterRolePage ไม่มี MapLibre/file upload จึงไม่เจอปัญหาเสถียรภาพแบบหน้า
  // farm/plot register ที่เคยประเมินความเสี่ยงไว้
  void _onNoAccountPressed(BuildContext context) {
    _log('ปุ่ม "ยังไม่มีบัญชีผู้ใช้" ถูกกด');

    final registerUrl = Uri.base.resolve('userRegister?from=liff').toString();
    _log('url=$registerUrl');

    bool isInClient = false;
    try {
      isInClient = liffIsInClient();
      _log('liffIsInClient()=$isInClient');
    } catch (e) {
      _log('liffIsInClient() throw: $e');
    }

    try {
      _log('เรียก liffOpenWindow(external:true)...');
      liffOpenWindow(registerUrl, external: true);
      _log('liffOpenWindow(external:true) return แล้วโดยไม่ throw');
    } catch (e) {
      _log('liffOpenWindow(external:true) throw: $e — ลอง external:false แทน');
      try {
        liffOpenWindow(registerUrl, external: false);
        _log('liffOpenWindow(external:false) return แล้วโดยไม่ throw');
      } catch (e2) {
        _log('liffOpenWindow(external:false) throw ด้วย: $e2');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เปิดหน้าสมัครสมาชิกไม่สำเร็จ: $e2'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
        if (_debugLog.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _debugLog
                  .map((line) => Text(
                        line,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
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
            onPressed: () => context.read<LiffLoginBloc>().add(LiffInitRequested()),
            child: const Text('ลองใหม่อีกครั้ง'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(LiffLoginSuccess state) {
    // ข้อความสรุปสำหรับ farmer โดยเฉพาะ (ไม่ใช่ debug detail อย่าง user_id/
    // line_user_id ที่เคยโชว์ไว้ตอนดีบัก) — ค้างไว้ 3 วินาทีก่อนปิดหน้าจอ LIFF
    // เอง (ดู listener ใน build() ด้านบน)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
          const SizedBox(height: 12),
          const Text(
            'ทำการผูกบัญชี Line สำเร็จ',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';

/// หน้าปลายทางหลังสมัครสมาชิก + ลงทะเบียนโปรไฟล์ (RegisterRolePage) สำเร็จ ผ่าน
/// flow ที่เริ่มจากปุ่ม "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing — พากลับไปหน้า LIFF
/// landing เดิมแบบ in-app (ไม่ redirect ออกนอก LIFF webview เลย เพราะทดสอบแล้วว่า
/// liff.openWindow ใช้ไม่ได้จริงบนอุปกรณ์/เวอร์ชัน LINE บางรุ่น — ดูคอมเมนต์ใน
/// liff_login_page.dart) เพื่อให้ผู้ใช้กด "มีบัญชีผู้ใช้แล้ว" เชื่อมบัญชี LINE ต่อได้เลย
class LiffRegisterSuccessPage extends StatefulWidget {
  const LiffRegisterSuccessPage({super.key});

  @override
  State<LiffRegisterSuccessPage> createState() => _LiffRegisterSuccessPageState();
}

class _LiffRegisterSuccessPageState extends State<LiffRegisterSuccessPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoute.liffLink,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      showBackButton: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
              const SizedBox(height: 16),
              const Text(
                'สมัครสำเร็จ!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              const Text(
                'กำลังพาท่านกลับไปเชื่อมบัญชี LINE...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cocoa_supply/config/liff_config.dart';
import 'package:cocoa_supply/services/web_redirect.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';

/// หน้าปลายทางหลังสมัครสมาชิก + ลงทะเบียนโปรไฟล์ (RegisterRolePage) สำเร็จ
/// ผ่าน flow ที่เปิดมาจากหน้า LIFF landing (liff.openWindow ไป browser ปกติ)
/// auto-redirect กลับเข้า liff.line.me/{liffId} ให้ OS เปิดแอป LINE พาไปหน้า
/// LIFF landing page เดิม เพื่อให้ผู้ใช้กด "มีบัญชีผู้ใช้แล้ว" เชื่อมบัญชี LINE ต่อได้เลย
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
      redirectTo('https://liff.line.me/$liffId');
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
                'กำลังพาท่านกลับเข้าแอป LINE เพื่อเชื่อมบัญชี...',
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

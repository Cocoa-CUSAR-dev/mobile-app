import 'package:flutter/material.dart';
import 'package:cocoa_supply/services/liff_service.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';

/// หน้าปลายทางหลังสมัครสมาชิก + เชื่อมบัญชี LINE (LiffLinkPage) + ลงทะเบียนโปรไฟล์
/// (RegisterRolePage) ครบทุกขั้นตอนแล้ว ผ่าน flow ที่เริ่มจากปุ่ม "ยังไม่มีบัญชีผู้ใช้"
/// บนหน้า LIFF landing — บัญชีพร้อมใช้งานสมบูรณ์แล้ว ปิดหน้าต่าง LIFF กลับไปที่
/// ช่องแชท LINE ให้เองเหมือน flow บัญชีเดิมปกติ (ดู liff_login_page.dart)
class LiffRegisterSuccessPage extends StatefulWidget {
  const LiffRegisterSuccessPage({super.key});

  @override
  State<LiffRegisterSuccessPage> createState() => _LiffRegisterSuccessPageState();
}

class _LiffRegisterSuccessPageState extends State<LiffRegisterSuccessPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      liffCloseWindow();
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
                'สมัครสมาชิกและเชื่อมบัญชี LINE สำเร็จ!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              const Text(
                'พร้อมใช้งานแล้ว กำลังปิดหน้าต่างนี้...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

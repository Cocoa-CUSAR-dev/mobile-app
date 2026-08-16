import 'package:flutter/material.dart';
import 'package:cocoa_supply/services/liff_service.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';

/// "Login success Page" ปลายทางร่วมของทุก flow ใน LiffLinkPage หลัง login/link
/// สำเร็จ + มีโปรไฟล์ (role) ครบแล้ว ไม่ว่าจะมาจากทางไหน — เดิมมีบัญชี+มีโปรไฟล์
/// อยู่แล้ว (ตรงมาเลย), เดิมมีบัญชีแต่ยังไม่มีโปรไฟล์ (ผ่าน RegisterRolePage มา),
/// หรือเพิ่งสมัครสมาชิกใหม่ (ผ่าน RegisterRolePage มาเช่นกัน เพราะบัญชีใหม่ไม่มี
/// โปรไฟล์แน่นอน) — ปิดหน้าต่าง LIFF กลับไปที่ช่องแชท LINE ให้เอง
class LiffLoginSuccessPage extends StatefulWidget {
  const LiffLoginSuccessPage({super.key});

  @override
  State<LiffLoginSuccessPage> createState() => _LiffLoginSuccessPageState();
}

class _LiffLoginSuccessPageState extends State<LiffLoginSuccessPage> {
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
                'เชื่อมบัญชี LINE สำเร็จ!',
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

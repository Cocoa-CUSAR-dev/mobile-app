import 'package:flutter/material.dart';
import 'package:cocoa_supply/route.dart';

class RegistrationSelectionPage extends StatelessWidget {
  const RegistrationSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // ส่วนหัวข้อ
              const Text(
                'คุณยังไม่ได้ลงทะเบียนเป็น\nเกษตรกร หรือ ผู้แปรรูป',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'กรุณาเลือกประเภทบัญชีที่คุณต้องการเริ่มต้นใช้งาน',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // ปุ่มสมัครเป็นเกษตรกร
              _buildSelectionButton(
                context: context,
                label: 'สมัครเป็นเกษตรกร',
                icon: Icons.agriculture,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoute.dynamicRegister,
                    arguments: {'tableName': 'farmer'}, 
                  );
                },
              ),

              const SizedBox(height: 20),

              // ปุ่มสมัครเป็นผู้แปรรูป
              _buildSelectionButton(
                context: context,
                label: 'สมัครเป็นผู้แปรรูป',
                icon: Icons.factory,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoute.dynamicRegister,
                    arguments: {'tableName': 'processor'},
                  );
                },
              ),
              
              const Spacer(),
              
              // ลิงก์กลับหน้าล็อกอิน (เผื่อเปลี่ยนใจ)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ย้อนกลับไปหน้าล็อกอิน',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มตัวเลือก
  Widget _buildSelectionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF794c46),
        side: const BorderSide(color: Color(0xFF794c46), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
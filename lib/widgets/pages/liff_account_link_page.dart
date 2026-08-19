import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/services/liff_service.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';

/// ปลายทางร่วมของทุก flow ใน LiffLinkPage/RegisterRolePage หลัง login สำเร็จ +
/// มีโปรไฟล์ (role) ครบแล้ว ไม่ว่าจะมาจากทางไหน — เดิมมีบัญชี+มีโปรไฟล์อยู่แล้ว
/// (ตรงมาจาก LiffLinkPage เลย), เดิมมีบัญชีแต่ยังไม่มีโปรไฟล์ หรือเพิ่งสมัคร
/// สมาชิกใหม่ (ทั้งคู่ผ่าน RegisterRolePage มาก่อน) — ผู้เรียก (LiffLinkPage หรือ
/// RegisterRolePage) ต้อง dispatch LiffLinkRequested(idToken) ไว้ก่อน navigate
/// มาที่นี่แล้ว หน้านี้แค่ฟัง state ที่ตามมา (LiffLinking → LiffLinkSuccess/
/// LiffLoginFailure) แสดงผล แล้วปิดหน้าต่าง LIFF กลับไปที่ช่องแชท LINE ให้เอง
class LiffAccountLinkPage extends StatefulWidget {
  const LiffAccountLinkPage({super.key});

  @override
  State<LiffAccountLinkPage> createState() => _LiffAccountLinkPageState();
}

class _LiffAccountLinkPageState extends State<LiffAccountLinkPage> {
  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      showBackButton: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<LiffLoginBloc, LiffLoginState>(
            listener: (context, state) {
              if (state is LiffLinkSuccess) {
                // โชว์ข้อความสำเร็จค้างไว้ 3 วินาที แล้วปิดหน้าจอ LIFF กลับไป
                // ที่ช่องแชท LINE ให้เอง — ไม่ต้องรอ user กดปิดเอง
                Future.delayed(const Duration(seconds: 3), () {
                  liffCloseWindow();
                });
              }
            },
            builder: (context, state) {
              if (state is LiffLinkSuccess) return _buildSuccess(state);
              if (state is LiffLoginFailure) return _buildError(context, state);
              // LiffLinking หรือสถานะอื่นระหว่างรอ (เช่น เพิ่งเข้าหน้านี้มา ยังไม่
              // ทันได้ LiffLinking) — โชว์ spinner ระหว่างรอผลผูกบัญชี
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังเชื่อมบัญชี LINE...', style: TextStyle(fontSize: 16)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(LiffLinkSuccess state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
        const SizedBox(height: 16),
        Text(
          // already_linked: true = เชื่อมกับ LINE นี้อยู่แล้วจากรอบก่อนหน้า
          // (เช่น login ซ้ำมากรอกโปรไฟล์ให้เสร็จ) — ต่างจากเพิ่งเชื่อมสำเร็จใหม่
          state.alreadyLinked ? 'บัญชีนี้เชื่อมกับ LINE อยู่แล้ว' : 'เชื่อมบัญชี LINE สำเร็จ!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 8),
        const Text(
          'พร้อมใช้งานแล้ว กำลังปิดหน้าต่างนี้...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, LiffLoginFailure state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade600, size: 64),
        const SizedBox(height: 16),
        const Text(
          'เชื่อมบัญชี LINE ไม่สำเร็จ',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          state.error,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        if (state.idToken != null)
          OutlinedButton(
            onPressed: () => context.read<LiffLoginBloc>().add(
                  LiffLinkRequested(idToken: state.idToken!),
                ),
            child: const Text('ลองใหม่อีกครั้ง'),
          ),
      ],
    );
  }
}

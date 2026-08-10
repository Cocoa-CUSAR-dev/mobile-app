import 'package:equatable/equatable.dart';

abstract class LiffLoginEvent extends Equatable {
  const LiffLoginEvent();
  @override
  List<Object> get props => [];
}

/// เรียกตอนหน้าโหลด (initState) — ให้ bloc ไป liff.init() แล้วโชว์หน้า landing
/// ("มีบัญชีแล้วหรือไม่?") ยังไม่ liff.login() จนกว่าจะรู้ว่าผู้ใช้เลือกอะไร
class LiffInitRequested extends LiffLoginEvent {}

/// เรียกตอนกดปุ่ม "มีบัญชีผู้ใช้แล้ว" บนหน้า landing — เริ่ม liff.login() (ถ้ายัง)
/// + liff.getIDToken() เพื่อไปโชว์ฟอร์มเชื่อมบัญชีเดิม
class LiffHasAccountPressed extends LiffLoginEvent {}

// หมายเหตุ: ปุ่ม "ยังไม่มีบัญชีผู้ใช้" ไม่ผ่าน event/bloc — เรียก liffOpenWindow()
// ตรงๆ แบบ sync ใน onPressed ของ LiffLinkPage เลย (ดูคอมเมนต์ที่นั่น)

/// เรียกตอนกดปุ่ม submit ฟอร์ม username/password (บัญชีเดิม)
class LiffLoginSubmitted extends LiffLoginEvent {
  final String username;
  final String password;

  const LiffLoginSubmitted({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

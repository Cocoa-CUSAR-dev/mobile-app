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

// หมายเหตุ: ปุ่ม "ยังไม่มีบัญชีผู้ใช้" ไม่ผ่าน event/bloc — navigate แบบ in-app
// (Navigator.pushNamed) ตรงๆ ใน onPressed ของ LiffLinkPage เลย (ดูคอมเมนต์ที่นั่น)

/// เรียกตอนกดปุ่ม submit ฟอร์ม username/password (บัญชีเดิม) — login อย่างเดียว
/// ไม่ผูกบัญชี LINE พร้อมกันแล้ว (แยกออกจากกันตาม flow ใหม่ — ดู LiffLinkRequested)
class LiffLoginSubmitted extends LiffLoginEvent {
  final String username;
  final String password;

  const LiffLoginSubmitted({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

/// เรียกหลัง login สำเร็จ (ไม่ว่าจะมีโปรไฟล์อยู่แล้ว หรือเพิ่งกรอกโปรไฟล์เสร็จที่
/// RegisterRolePage) เพื่อผูกบัญชี LINE ผ่าน POST /line/link (protected, รู้ตัวตน
/// จาก cookie ที่ login ไว้แล้ว) — idempotent: ถ้าเชื่อมกับ LINE นี้อยู่แล้ว
/// backend จะตอบสำเร็จเลย ไม่ error (ไม่บล็อก user ที่ login ซ้ำแต่ยังไม่มีโปรไฟล์)
class LiffLinkRequested extends LiffLoginEvent {
  final String idToken;

  const LiffLinkRequested({required this.idToken});

  @override
  List<Object> get props => [idToken];
}

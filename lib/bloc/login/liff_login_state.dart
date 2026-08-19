import 'package:equatable/equatable.dart';

abstract class LiffLoginState extends Equatable {
  const LiffLoginState();
  @override
  List<Object?> get props => [];
}

/// ยังไม่เริ่ม liff.init()
class LiffLoginInitial extends LiffLoginState {}

/// กำลัง liff.init() / รอ LINE redirect กลับมา
class LiffInitializing extends LiffLoginState {}

/// liff.init() สำเร็จ รอผู้ใช้เลือกว่า "มีบัญชีผู้ใช้แล้ว" หรือ "ยังไม่มีบัญชีผู้ใช้"
class LiffLanding extends LiffLoginState {}

/// liff.init() สำเร็จ ได้ ID token จาก LINE แล้ว พร้อมให้กรอกฟอร์มบัญชีเดิม
class LiffReady extends LiffLoginState {
  final String idToken;
  const LiffReady({required this.idToken});
  @override
  List<Object> get props => [idToken];
}

/// กำลังส่ง idToken + username/password ไป backend เพื่อ verify
class LiffLoginLoading extends LiffLoginState {
  final String idToken;
  const LiffLoginLoading({required this.idToken});
  @override
  List<Object> get props => [idToken];
}

/// login (username/password) สำเร็จ — ยังไม่ได้ผูกบัญชี LINE (แยกออกจากกันแล้ว)
/// เก็บ idToken ไว้ต่อเพื่อใช้ตอนผูกบัญชี LINE ในขั้นต่อไป
class LiffLoggedIn extends LiffLoginState {
  final String idToken;
  /// จาก has_profile ของ backend (ตรรกะเดียวกับ next_page ของ Login ปกติ) —
  /// true = มีโปรไฟล์ (role) แล้ว ไปผูกบัญชี LINE ต่อได้เลย, false = ต้องไปกรอก
  /// โปรไฟล์ที่ RegisterRolePage ก่อน แล้วค่อยผูกบัญชี LINE
  final bool hasProfile;

  const LiffLoggedIn({required this.idToken, required this.hasProfile});

  @override
  List<Object> get props => [idToken, hasProfile];
}

/// กำลังเรียก POST /line/link เพื่อผูกบัญชี LINE
class LiffLinking extends LiffLoginState {
  final String idToken;
  const LiffLinking({required this.idToken});
  @override
  List<Object> get props => [idToken];
}

/// ผูกบัญชี LINE ผ่าน (idempotent — สำเร็จได้ทั้งกรณีผูกใหม่ และกรณีเชื่อมกับ
/// LINE นี้อยู่แล้วมาก่อน) ดู already_linked ว่าเป็นกรณีไหน เพื่อเลือกข้อความ
/// ที่โชว์ให้ตรงกับสถานการณ์จริง
class LiffLinkSuccess extends LiffLoginState {
  final bool alreadyLinked;
  final String lineUserId;
  final String message;

  const LiffLinkSuccess({
    required this.alreadyLinked,
    required this.lineUserId,
    required this.message,
  });

  @override
  List<Object> get props => [alreadyLinked, lineUserId, message];
}

class LiffLoginFailure extends LiffLoginState {
  final String error;
  /// ถ้าไม่ null แปลว่า error นี้เกิด "หลังจาก" มี idToken ที่ verify กับ LINE
  /// สำเร็จแล้ว (เช่น submit username/password ไม่ผ่าน) — UI ควรยังโชว์ฟอร์ม
  /// ให้กรอกใหม่ได้ ต่างจาก error ตอน liff.init() เอง (idToken เป็น null)
  /// ที่ไม่มี idToken ให้ submit เลย ไม่ควรโชว์ฟอร์ม
  final String? idToken;

  const LiffLoginFailure({required this.error, this.idToken});

  @override
  List<Object?> get props => [error, idToken];
}

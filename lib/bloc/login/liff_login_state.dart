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

/// backend verify กับ LINE สำเร็จ — ได้ line_user_id จริงที่ verify แล้วกลับมา
class LiffLoginSuccess extends LiffLoginState {
  final String userId;
  final String lineUserId;
  final String message;

  const LiffLoginSuccess({
    required this.userId,
    required this.lineUserId,
    required this.message,
  });

  @override
  List<Object> get props => [userId, lineUserId, message];
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

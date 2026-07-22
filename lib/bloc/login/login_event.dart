import 'package:equatable/equatable.dart';

// Abstract class สำหรับ Event ทั้งหมดที่เกี่ยวข้องกับการ Login
abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

// Event เมื่อผู้ใช้คลิกปุ่ม Login
class LoginButtonPressed extends LoginEvent {
  final String username;
  final String password;

  const LoginButtonPressed({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class LoadLogin extends LoginEvent {}

// Event เมื่อผู้ใช้ต้องการสลับไปหน้า Register (อาจจะใช้ในการนำทาง)
class LoginNavigateToRegister extends LoginEvent {}
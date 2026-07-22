import 'package:equatable/equatable.dart';

// Abstract class สำหรับ State ทั้งหมดที่เกี่ยวข้องกับการ Login
abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object> get props => [];
}

// สถานะเริ่มต้นของหน้า Login
class LoginInitial extends LoginState {}

// สถานะเมื่อกำลังประมวลผลการ Login
class LoginLoading extends LoginState {}

// สถานะเมื่อ Login สำเร็จ
class LoginSuccess extends LoginState {
  final String next_page;
  const LoginSuccess({required this.next_page});
  @override
  List<Object> get props => [next_page];
}

// สถานะเมื่อ Login ล้มเหลว
class LoginFailure extends LoginState {
  final String error;
  const LoginFailure({required this.error});
  @override
  List<Object> get props => [error];
}
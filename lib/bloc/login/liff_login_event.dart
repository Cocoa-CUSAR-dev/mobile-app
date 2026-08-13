import 'package:equatable/equatable.dart';

abstract class LiffLoginEvent extends Equatable {
  const LiffLoginEvent();
  @override
  List<Object> get props => [];
}

/// เรียกตอนหน้าโหลด (initState) — ให้ bloc ไป liff.init() + liff.login() (ถ้ายัง)
/// แล้วดึง ID token มาเตรียมไว้
class LiffInitRequested extends LiffLoginEvent {}

/// เรียกตอนกดปุ่ม submit ฟอร์ม username/password (บัญชีเดิม)
class LiffLoginSubmitted extends LiffLoginEvent {
  final String username;
  final String password;

  const LiffLoginSubmitted({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
// import 'package:cocoa_supply/core/api/auth_repository.dart'; // สมมติว่ามี repository

// LoginBloc: จัดการการ Login และสถานะที่เกี่ยวข้อง
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  // final AuthRepository authRepository;
  final loginService = ServiceProvider(storageKey: 'token', endpoint: '/public/login', isRealApi: true, useCookie: false);
  LoginBloc() : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LoadLogin>(_onLoadLogin);
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(LoginLoading());
      // จำลองเงื่อนไขสำเร็จ/ล้มเหลว
      if (event.username == 'admin' && event.password == 'password') {
        const mockToken = 'mock-jwt-token-12345';
        // ไปหน้า login success
        emit(const LoginSuccess(next_page: mockToken));
        
      } else {
        final loginService = ServiceProvider(storageKey: 'token', endpoint: '/public/login', isRealApi: true, useCookie: false);
        try {
          final response = await loginService.postData({
            'username': event.username,
            'password': event.password,
          });
          print(response);
          if (response["has_profile"] == true){
            // ถ้าผ่านปุ๊บ Request ถัดไปที่ใช้ ServiceProvider ตัวอื่นจะแนบ Cookie ให้เองทันที!
            emit(LoginSuccess(next_page: 'HOME')); //มีโปรไฟล์แล้ว
          }else{
            emit(LoginSuccess(next_page: 'REGIS_ROLE')); //ยังไม่มีโปรไฟล์ ต้องไป regis role ก่อน
          }
        } catch (e) {
          emit(LoginFailure(error: e.toString()));
        }
      }
    } catch (e) {
      // กรณีเกิดข้อผิดพลาดอื่นๆ (เช่น Network Error)
      emit(LoginFailure(error: 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}'));
    }
  }
  Future<void> _onLoadLogin( 
    LoadLogin event,
    Emitter<LoginState> emit,
  ) async {
    if (await loginService.isLoggedIn()){
      emit(LoginSuccess(next_page: 'HOME'));
    }
  }
}
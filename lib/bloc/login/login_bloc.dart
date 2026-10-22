import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/login/login_state.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/bloc/login/login_event.dart';
import 'package:http/http.dart' as http;
// import 'package:cocoa_supply/core/api/auth_repository.dart'; // สมมติว่ามี repository

// LoginBloc: จัดการการ Login และสถานะที่เกี่ยวข้อง
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  // final AuthRepository authRepository;
  final http.Client? _client;
  late final loginService = ServiceProvider(
    storageKey: 'token',
    endpoint: '/api/v1/auth/login',
    isRealApi: true,
    useCookie: false,
    useHub: true,
    client: _client,
  );

  LoginBloc({http.Client? client}) : _client = client, super(LoginInitial()) {
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
        try {
          final response = await loginService.postData({
            'username': event.username,
            'password': event.password,
          });
          print(response);
          // backend-hub: {access_token, refresh_token, user: {roles, ...}} --
          // ServiceProvider เก็บ token ให้แล้ว request ถัดไปแนบ Bearer เอง
          // ยังไม่มี role ใดเลย = ยังไม่มีโปรไฟล์ ต้องไปเลือก/ลงทะเบียน role ก่อน
          final user = response is Map ? response['user'] : null;
          final List roles = user is Map ? (user['roles'] ?? []) : [];
          if (roles.isNotEmpty){
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
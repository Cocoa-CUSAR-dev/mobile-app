import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/config/liff_config.dart';
import 'package:cocoa_supply/services/liff_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';

/// LiffLoginBloc: flow "existing farmer เชื่อมบัญชีผ่าน LINE LIFF"
/// 1. liff.init() + liff.getIDToken() ฝั่ง frontend (ผ่าน liff_service.dart)
/// 2. ส่ง idToken + username/password ไป POST /public/liff/link ให้ backend
///    verify กับ LINE จริงๆ แล้วคืน line_user_id ที่ verify แล้วกลับมา
///    (ดู LinkLineAccount ใน mobile-backend/internal/handlers/auth_handler.go)
class LiffLoginBloc extends Bloc<LiffLoginEvent, LiffLoginState> {
  final _linkService = ServiceProvider(
    storageKey: 'liff_link',
    endpoint: '/public/liff/link',
    isRealApi: true,
    useCookie: false,
  );

  LiffLoginBloc() : super(LiffLoginInitial()) {
    on<LiffInitRequested>(_onLiffInitRequested);
    on<LiffLoginSubmitted>(_onLiffLoginSubmitted);
  }

  Future<void> _onLiffInitRequested(
    LiffInitRequested event,
    Emitter<LiffLoginState> emit,
  ) async {
    emit(LiffInitializing());
    try {
      if (liffId.isEmpty) {
        throw Exception('ยังไม่ได้ตั้งค่า LIFF_ID (--dart-define=LIFF_ID=...)');
      }

      await liffInit(liffId);

      if (!liffIsLoggedIn()) {
        // liffLogin() จะ redirect ทั้งหน้าไปหน้า login ของ LINE เอง
        // (หน้านี้จะถูกทำลายไป ไม่ต้อง emit อะไรต่อ)
        liffLogin();
        return;
      }

      final idToken = liffGetIDToken();
      if (idToken == null) {
        throw Exception(
          'liff.getIDToken() คืนค่า null — เช็คว่า LIFF app เปิด scope "openid" ไว้หรือยัง',
        );
      }

      emit(LiffReady(idToken: idToken));
    } catch (e) {
      emit(LiffLoginFailure(error: e.toString()));
    }
  }

  Future<void> _onLiffLoginSubmitted(
    LiffLoginSubmitted event,
    Emitter<LiffLoginState> emit,
  ) async {
    final currentState = state;
    if (currentState is! LiffReady) {
      emit(const LiffLoginFailure(error: 'ยังไม่มี idToken จาก LINE ให้ส่งไป verify'));
      return;
    }

    final idToken = currentState.idToken;
    emit(LiffLoginLoading(idToken: idToken));

    try {
      final response = await _linkService.postData({
        'idToken': idToken,
        'username': event.username,
        'password': event.password,
      });

      emit(LiffLoginSuccess(
        userId: response['user_id']?.toString() ?? '',
        lineUserId: response['line_user_id']?.toString() ?? '',
        message: response['message']?.toString() ?? 'เชื่อมบัญชีสำเร็จ',
      ));
    } catch (e) {
      // แนบ idToken เดิมกลับไปด้วย — error นี้เกิดตอน submit (username/password
      // ผิด หรือ backend error) ไม่ใช่ idToken หมดอายุ/หาไม่เจอ ให้ UI รู้ว่า
      // ยังกรอกฟอร์มใหม่ได้เลยไม่ต้องเริ่ม liff.init() ใหม่
      emit(LiffLoginFailure(error: e.toString(), idToken: idToken));
    }
  }
}

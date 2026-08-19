import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/config/liff_config.dart';
import 'package:cocoa_supply/services/liff_service.dart';
import 'package:cocoa_supply/services/service_provider.dart';

/// LiffLoginBloc: flow "existing farmer เชื่อมบัญชีผ่าน LINE LIFF"
/// login กับผูกบัญชี LINE แยกเป็นคนละขั้นตอนกัน (ไม่รวมกันในคำขอเดียวแบบเดิม):
/// 1. liff.init() + liff.getIDToken() ฝั่ง frontend (ผ่าน liff_service.dart)
/// 2. ส่ง username/password ไป POST /public/login (endpoint เดียวกับ login
///    ปกติ) — ได้ session cookie + has_profile กลับมา
/// 3. ส่ง idToken ไป POST /line/link (protected, รู้ตัวตนจาก cookie ข้อ 2)
///    เพื่อผูกบัญชี LINE — idempotent เชื่อมกับ LINE นี้อยู่แล้วก็ถือว่าสำเร็จ
///    ไม่ error (ดู LinkLineIdentity ใน mobile-backend/internal/handlers/auth_handler.go)
/// แยกแบบนี้เพื่อให้ user ที่มีบัญชี+เชื่อม LINE ไปแล้วแต่ยังไม่มีโปรไฟล์ login
/// ซ้ำเข้ามาได้โดยไม่ถูกบล็อกด้วย error "ผูกไปแล้ว" ที่ขั้นตอนผูกบัญชี LINE
class LiffLoginBloc extends Bloc<LiffLoginEvent, LiffLoginState> {
  final _loginService = ServiceProvider(
    storageKey: 'liff_login',
    endpoint: '/public/login',
    isRealApi: true,
  );

  final _lineLinkService = ServiceProvider(
    storageKey: 'line_link',
    endpoint: '/line/link',
    isRealApi: true,
  );

  LiffLoginBloc() : super(LiffLoginInitial()) {
    on<LiffInitRequested>(_onLiffInitRequested);
    on<LiffHasAccountPressed>(_onLiffHasAccountPressed);
    on<LiffLoginSubmitted>(_onLiffLoginSubmitted);
    on<LiffLinkRequested>(_onLiffLinkRequested);
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

      // ยังไม่ liff.login()/getIDToken() ที่นี่ — รอให้ผู้ใช้เลือกก่อนว่ามีบัญชี
      // อยู่แล้วหรือยัง (สมัครใหม่ผ่าน browser ปกติไม่จำเป็นต้องมี idToken)
      emit(LiffLanding());
    } catch (e) {
      emit(LiffLoginFailure(error: e.toString()));
    }
  }

  Future<void> _onLiffHasAccountPressed(
    LiffHasAccountPressed event,
    Emitter<LiffLoginState> emit,
  ) async {
    emit(LiffInitializing());
    try {
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
      // login อย่างเดียว — ยังไม่ผูกบัญชี LINE ตรงนี้ (ดู LiffLinkRequested)
      final response = await _loginService.postData({
        'username': event.username,
        'password': event.password,
      });

      emit(LiffLoggedIn(
        idToken: idToken,
        hasProfile: response['has_profile'] == true,
      ));
    } catch (e) {
      // แนบ idToken เดิมกลับไปด้วย — error นี้เกิดตอน submit (username/password
      // ผิด หรือ backend error) ไม่ใช่ idToken หมดอายุ/หาไม่เจอ ให้ UI รู้ว่า
      // ยังกรอกฟอร์มใหม่ได้เลยไม่ต้องเริ่ม liff.init() ใหม่
      emit(LiffLoginFailure(error: e.toString(), idToken: idToken));
    }
  }

  Future<void> _onLiffLinkRequested(
    LiffLinkRequested event,
    Emitter<LiffLoginState> emit,
  ) async {
    emit(LiffLinking(idToken: event.idToken));
    try {
      final response = await _lineLinkService.postData({
        'idToken': event.idToken,
      });

      emit(LiffLinkSuccess(
        alreadyLinked: response['already_linked'] == true,
        lineUserId: response['line_user_id']?.toString() ?? '',
        message: response['message']?.toString() ?? 'เชื่อมบัญชี LINE สำเร็จ',
      ));
    } catch (e) {
      emit(LiffLoginFailure(error: e.toString(), idToken: event.idToken));
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:cocoa_supply/config/liff_config.dart';
import 'package:cocoa_supply/services/liff_api.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

/// Events of one kind run one after the other, never at the same time (bloc's
/// default is concurrent). Two inits, or two logins, at once each write their
/// own PKCE verifier, and LINE then refuses the code that belongs to the other
/// one ("code_verifier does not match").
EventTransformer<E> _oneAtATime<E>() =>
    (events, mapper) => events.asyncExpand(mapper);

/// LiffLoginBloc: flow "existing farmer เชื่อมบัญชีผ่าน LINE LIFF"
/// 1. liff.init() + liff.getIDToken() ฝั่ง frontend (ผ่าน liff_api.dart)
/// 2. ถ้า LINE นี้ผูกบัญชีไว้แล้ว (POST /auth/line/login ได้ token) ข้าม landing ไป
///    หน้าสำเร็จเลย — ไม่ต้องถามซ้ำว่ามีบัญชีไหม
/// 3. ถ้ายังไม่ผูก: ส่ง idToken + username/password ไป POST /auth/line/link ให้
///    backend verify กับ LINE จริงๆ แล้วผูกบัญชีให้ (ดู line_link ใน
///    backend-hub src/auth/service.py)
class LiffLoginBloc extends Bloc<LiffLoginEvent, LiffLoginState> {
  final http.Client? _client;
  final LiffApi _liff;
  late final _linkService = ServiceProvider(
    storageKey: 'liff_link',
    endpoint: ApiEndpoints.authLineLink,
    isRealApi: true,
    useCookie: false,
    client: _client,
  );
  late final _lineLoginService = ServiceProvider(
    storageKey: 'liff_line_login',
    endpoint: ApiEndpoints.authLineLogin,
    isRealApi: true,
    useCookie: false,
    client: _client,
  );

  LiffLoginBloc({http.Client? client, LiffApi liff = const LiffApi()})
    : _client = client,
      _liff = liff,
      super(LiffLoginInitial()) {
    on<LiffInitRequested>(_onLiffInitRequested, transformer: _oneAtATime());
    on<LiffHasAccountPressed>(
      _onLiffHasAccountPressed,
      transformer: _oneAtATime(),
    );
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

      await _liff.init(liffId);

      // Already signed in with LINE and already linked: nothing to ask.
      final idToken = _liff.isLoggedIn ? _liff.idToken : null;
      if (idToken != null) {
        final linked = await _signInIfLinked(idToken);
        if (linked != null) {
          emit(linked);
          return;
        }
      }

      // ยังไม่ liff.login()/getIDToken() ที่นี่ — รอให้ผู้ใช้เลือกก่อนว่ามีบัญชี
      // อยู่แล้วหรือยัง (สมัครใหม่ผ่าน browser ปกติไม่จำเป็นต้องมี idToken)
      emit(LiffLanding());
    } catch (e) {
      emit(LiffLoginFailure(error: e.toString()));
    }
  }

  /// POST /auth/line/login: the token pair (stored by the ServiceProvider) when
  /// this LINE account is linked, 403 when it is not. Only a nice-to-have, so
  /// any other answer, or no answer, is the same as "not linked": the person
  /// still gets the landing page and can link as before.
  Future<LiffLoginSuccess?> _signInIfLinked(String idToken) async {
    try {
      final response = await _lineLoginService.postData({'id_token': idToken});
      return _successOf(response, 'บัญชีนี้เชื่อมกับ LINE อยู่แล้ว');
    } catch (_) {
      return null;
    }
  }

  Future<void> _onLiffHasAccountPressed(
    LiffHasAccountPressed event,
    Emitter<LiffLoginState> emit,
  ) async {
    emit(LiffInitializing());
    try {
      if (!_liff.isLoggedIn) {
        // liffLogin() จะ redirect ทั้งหน้าไปหน้า login ของ LINE เอง
        // (หน้านี้จะถูกทำลายไป ไม่ต้อง emit อะไรต่อ)
        _liff.login();
        return;
      }

      final idToken = _liff.idToken;
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
    // A refused submit keeps its idToken, so the form can be sent again.
    final currentState = state;
    final String? idToken = currentState is LiffReady
        ? currentState.idToken
        : currentState is LiffLoginFailure
        ? currentState.idToken
        : null;
    if (idToken == null) {
      emit(
        const LiffLoginFailure(
          error: 'ยังไม่มี idToken จาก LINE ให้ส่งไป verify',
        ),
      );
      return;
    }

    emit(LiffLoginLoading(idToken: idToken));

    try {
      final response = await _linkService.postData({
        'id_token': idToken,
        'username': event.username,
        'password': event.password,
      });

      emit(
        _successOf(
          response,
          'verify สำเร็จ และบันทึกการผูกบัญชี LINE เรียบร้อยแล้ว',
        ),
      );
    } catch (e) {
      // แนบ idToken เดิมกลับไปด้วย — error นี้เกิดตอน submit (username/password
      // ผิด หรือ backend error) ไม่ใช่ idToken หมดอายุ/หาไม่เจอ ให้ UI รู้ว่า
      // ยังกรอกฟอร์มใหม่ได้เลยไม่ต้องเริ่ม liff.init() ใหม่
      emit(LiffLoginFailure(error: e.toString(), idToken: idToken));
    }
  }

  /// The backend answers with the token pair (already stored by the
  /// ServiceProvider) and the account; having a role is having a profile.
  LiffLoginSuccess _successOf(dynamic response, String message) {
    final Object? user = response['user'];
    final Object? roles = user is Map ? user['roles'] : null;
    return LiffLoginSuccess(
      userId: (user is Map ? user['user_id'] : null)?.toString() ?? '',
      lineUserId: '',
      message: message,
      hasProfile: roles is List && roles.isNotEmpty,
    );
  }
}

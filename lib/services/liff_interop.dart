import 'dart:js_interop';

// {liffId: "..."} object literal ฝั่ง JS
extension type LiffInitOptions._(JSObject _) implements JSObject {
  external factory LiffInitOptions({required String liffId});
}

@JS('liff.init')
external JSPromise<JSAny?> _liffInit(LiffInitOptions options);

@JS('liff.isLoggedIn')
external bool liffIsLoggedIn();

@JS('liff.login')
external void liffLogin();

@JS('liff.getIDToken')
external JSString? _liffGetIDToken();

@JS('liff.closeWindow')
external void liffCloseWindow();

Future<void>? _initInFlight;

/// liff.init() runs ONCE per page. When there is no login yet, init (or login)
/// writes the PKCE verifier of the login it starts to localStorage and sends
/// the page to LINE; a second init in that moment overwrites the verifier, and
/// LINE then refuses the code that belongs to the first one ("code_verifier
/// does not match"). Everyone who asks shares the one in flight; a failed init
/// may be asked for again.
Future<void> liffInit(String liffId) {
  final inFlight = _initInFlight;
  if (inFlight != null) return inFlight;
  final started = _liffInit(LiffInitOptions(liffId: liffId)).toDart.then<void>(
    (_) {},
    onError: (Object error, StackTrace stack) {
      _initInFlight = null;
      Error.throwWithStackTrace(error, stack);
    },
  );
  _initInFlight = started;
  return started;
}

String? liffGetIDToken() => _liffGetIDToken()?.toDart;

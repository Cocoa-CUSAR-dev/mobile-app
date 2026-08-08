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

Future<void> liffInit(String liffId) =>
    _liffInit(LiffInitOptions(liffId: liffId)).toDart;

String? liffGetIDToken() => _liffGetIDToken()?.toDart;
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

// {url: "...", external: true} object literal ฝั่ง JS
extension type LiffOpenWindowOptions._(JSObject _) implements JSObject {
  external factory LiffOpenWindowOptions({required String url, required bool external});
}

@JS('liff.openWindow')
external void _liffOpenWindow(LiffOpenWindowOptions options);

Future<void> liffInit(String liffId) =>
    _liffInit(LiffInitOptions(liffId: liffId)).toDart;

String? liffGetIDToken() => _liffGetIDToken()?.toDart;

/// external:true = เปิด browser ปกติของเครื่อง (นอก LIFF webview) เช่นหน้าสมัครสมาชิก
/// ที่ต้องใช้ MapLibre/file upload ซึ่งไม่เสถียรถ้าเปิดค้างอยู่ใน LINE in-app webview
void liffOpenWindow(String url, {bool external = true}) =>
    _liffOpenWindow(LiffOpenWindowOptions(url: url, external: external));
// lib/services/liff_stub.dart
// ใช้แทน liff_web.dart ตอน build ที่ไม่ใช่ web (Android/iOS) — dart:js_interop
// ใช้ไม่ได้นอก web จึงต้องมีเวอร์ชันเปล่าไว้ให้โค้ด compile ผ่าน
// หน้าที่เรียกฟังก์ชันพวกนี้ (LiffLinkPage) มีความหมายเฉพาะบน web เท่านั้นอยู่แล้ว
// จึงไม่มีทางถูกเรียกจริงบนมือถือ แต่ยังต้อง provide signature เดียวกันไว้กันคอมไพล์พัง

Future<void> liffInit(String liffId) async {
  throw UnsupportedError('LIFF ใช้งานได้เฉพาะบน web build เท่านั้น');
}

bool liffIsLoggedIn() => false;

void liffLogin() {}

String? liffGetIDToken() => null;

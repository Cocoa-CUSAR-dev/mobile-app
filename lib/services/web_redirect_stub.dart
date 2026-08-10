// lib/services/web_redirect_stub.dart
// ใช้แทน web_redirect_web.dart ตอน build ที่ไม่ใช่ web (Android/iOS) — หน้าที่เรียก
// redirectTo (LiffRegisterSuccessPage) มีความหมายเฉพาะบน web เท่านั้น จึงไม่มีทาง
// ถูกเรียกจริงบนมือถือ แต่ยังต้อง provide signature เดียวกันไว้กันคอมไพล์พัง

void redirectTo(String url) {}

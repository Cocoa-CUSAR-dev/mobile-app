// lib/services/web_redirect_web.dart
import 'dart:js_interop';

@JS('window.location.href')
external set _locationHref(String url);

/// นำ tab ปัจจุบันไปยัง url ทันที (full page navigation ไม่ใช่ SPA route)
/// ใช้พาผู้ใช้ที่สมัครสมาชิกเสร็จใน browser ปกติกลับเข้า liff.line.me/{id}
/// ให้ OS เปิดแอป LINE ให้เอง
void redirectTo(String url) => _locationHref = url;

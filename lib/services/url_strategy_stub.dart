// lib/services/url_strategy_stub.dart
// ใช้แทน url_strategy_web.dart ตอน build ที่ไม่ใช่ web (Android/iOS/VM test
// target) — flutter_web_plugins ใช้ dart:ui_web ซึ่งใช้ไม่ได้นอก web จึงต้องมี
// เวอร์ชันเปล่าไว้ให้โค้ด compile ผ่าน (path-based routing มีความหมายเฉพาะบน
// web เท่านั้นอยู่แล้ว)

void configureUrlStrategy() {}

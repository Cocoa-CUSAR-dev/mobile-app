// lib/services/http_client_factory_stub.dart
// ใช้แทน http_client_factory_web.dart ตอน build ที่ไม่ใช่ web (Android/iOS) —
// package:http/browser_client.dart ใช้ได้เฉพาะ web เท่านั้น ฝั่ง native ใช้
// http.Client() ปกติ (IOClient) ซึ่งอ่าน Set-Cookie / ตั้ง Cookie header เองได้
// อยู่แล้ว ไม่มีข้อจำกัดแบบ browser จึงไม่ต้องมี withCredentials อะไรเพิ่ม
import 'package:http/http.dart' as http;

http.Client createHttpClient() => http.Client();

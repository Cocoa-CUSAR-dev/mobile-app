// lib/services/http_client_factory_web.dart
// เวอร์ชันจริงตอน build เป็น web — browser ไม่ยอมให้ JS อ่าน Set-Cookie จาก
// response หรือตั้ง Cookie header เองตอน request เลย (forbidden ตาม Fetch spec
// เสมอ ไม่ว่าจะ config CORS ยังไง) การแนบ Cookie header เองที่ ServiceProvider
// ทำอยู่จึงใช้ไม่ได้บน web เลย (ใช้ได้เฉพาะ native ที่ผ่าน IOClient) — ต้องพึ่ง
// browser ส่ง cookie ให้เองแทน โดยเปิด withCredentials (fetch's credentials:
// 'include') ให้ทุก request ข้าม origin (frontend อยู่ github.io, backend อยู่
// onrender.com) แนบ cookie ที่ backend set (SameSite=None; Secure) ไปด้วยอัตโนมัติ
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createHttpClient() => BrowserClient()..withCredentials = true;

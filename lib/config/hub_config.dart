// lib/config/hub_config.dart
// backend-hub: ที่ login / สมัคร / ต่ออายุ token / เพิ่ม role / ผูก LINE
// ตั้งค่าตอน build ด้วย --dart-define=HUB_BASE_URL=https://... (เหมือน API_BASE_URL)
// API อื่น ๆ ยังเรียก mobile-backend (API_BASE_URL) จนกว่าจะย้ายมา hub
// mobile-backend รับ token ของ hub ได้เลย (ใช้ JWT_KEY เดียวกัน) จึง login ที่เดียว
const hubBaseUrl = String.fromEnvironment('HUB_BASE_URL', defaultValue: '');

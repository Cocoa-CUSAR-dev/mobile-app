// lib/config/liff_config.dart
// ตั้งค่าตอน build/run ด้วย --dart-define=LIFF_ID=xxxx (ไม่ hardcode ในโค้ด)
// LIFF ID ไม่ใช่ความลับ (โผล่อยู่ใน URL liff.line.me/{id} ที่แชร์กันอยู่แล้ว)
// แค่ทำให้เปลี่ยนระหว่าง dev/staging/prod ได้โดยไม่ต้องแก้โค้ด
const liffId = String.fromEnvironment('LIFF_ID', defaultValue: '2010930353-4bm8N7wN');

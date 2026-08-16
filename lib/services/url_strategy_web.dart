// lib/services/url_strategy_web.dart
// เวอร์ชันจริงตอน build เป็น web — เปิด path-based routing (จำเป็นสำหรับ LIFF
// ดู lib/main.dart สำหรับรายละเอียดว่าทำไมถึงต้องใช้)

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void configureUrlStrategy() => usePathUrlStrategy();

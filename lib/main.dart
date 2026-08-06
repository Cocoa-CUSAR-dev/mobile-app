import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  // path-based routing (/liff-link แทน #/liff-link) — จำเป็นสำหรับ LIFF
  // เพราะ LINE ต่อ query string (?liff.state=...) เข้ากับ Endpoint URL ตอน
  // redirect กลับจาก login ซึ่งใช้กับ URL ที่มี #fragment ไม่ได้ (query หลัง
  // fragment จะกลายเป็นส่วนหนึ่งของ fragment ไปเลยตาม URL spec)
  //
  // Deploy อยู่บน GitHub Pages ซึ่งไม่รองรับ server-side rewrite ให้
  // path-based SPA routing ทำงานเองได้ — ต้องพึ่ง web/404.html +
  // สคริปต์ต้น web/index.html (rafgraph/spa-github-pages pattern) คู่กัน
  // ถึงจะใช้ path ตรงๆ บน GitHub Pages ได้จริง อย่าลบสองไฟล์นั้นทิ้ง
  usePathUrlStrategy();

  // TEMP DEBUG — คู่กับ debug overlay ใน web/index.html: release build จะกลืน
  // exception เงียบๆ (จอขาวเฉยๆ ไม่มี red screen แบบ debug) hook สองตัวนี้
  // ดัน error ออก print → console.log → โผล่ใน overlay บนมือถือ ลบออกพร้อม overlay
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('[UncaughtError] $error');
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: AppBloc.providers,
      child: MaterialApp(
        title: 'Cacao Farmer App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'NotoSansThaiLooped',
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        initialRoute: AppRoute.login,
        onGenerateRoute: AppRoute.onGenerateRoute,
        // ค่า default ของ Flutter (Navigator.defaultGenerateInitialRoutes)
        // จะสร้างหน้า home ('/') ซ้อนอยู่ข้างใต้ก่อนเสมอ แล้วค่อย push หน้าที่
        // deep-link มาจริงทับ (เพื่อให้ปุ่มย้อนกลับกลับไปหน้าแรกได้) — ผลคือ
        // LoginPage.initState() ทำงานคู่ขนานไปด้วยทุกครั้งที่เข้าแอปด้วย
        // deep link (เช่น /liff-link จาก LINE) ทั้งที่ไม่ได้ต้องการ ยิง
        // isLoggedIn()/LoadLogin โดยไม่จำเป็น — override ให้ build แค่ route
        // ที่ตรงกับ URL จริงตัวเดียว ไม่ต้องสร้าง home ซ้อนไว้ข้างใต้
        onGenerateInitialRoutes: (String initialRouteName) {
          final route = AppRoute.onGenerateRoute(RouteSettings(name: initialRouteName));
          return route != null ? [route] : [];
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('th', 'TH'), // ภาษาไทย
          Locale('en', 'US'), // ภาษาอังกฤษ (เผื่อไว้)
        ],
        locale: const Locale('th', 'TH'),
      ),
    );
  }
}

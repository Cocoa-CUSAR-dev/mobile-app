import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cocoa_supply/services/url_strategy.dart';

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
  //
  // configureUrlStrategy() (lib/services/url_strategy.dart) is a no-op
  // stub off web (dart.library.js_interop conditional import, same
  // pattern as liff_service.dart) — flutter_web_plugins needs
  // dart:ui_web, which isn't available on the VM test target or native
  // builds, so it can't be called/imported unconditionally here.
  configureUrlStrategy();
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
          pageTransitionsTheme: PageTransitionsTheme(
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

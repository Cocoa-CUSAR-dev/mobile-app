import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  // ใช้ path ปกติ (/liff-link) แทน hash (#/liff-link) — จำเป็นสำหรับให้
  // LIFF Endpoint URL ชี้มาที่ path ตรงๆ ได้ (no-op บน mobile โดยอัตโนมัติ)
  usePathUrlStrategy();
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

import 'package:cocoa_supply/widgets/pages/liff_login_page.dart';
import 'package:cocoa_supply/widgets/pages/farm_register_page.dart';
import 'package:cocoa_supply/widgets/pages/hub_register_page.dart';
import 'package:cocoa_supply/widgets/pages/plot_register_page.dart';
import 'package:cocoa_supply/widgets/pages/processing_station_register_page.dart';
import 'package:cocoa_supply/widgets/pages/register_role_page.dart';
import 'package:cocoa_supply/widgets/pages/user_register_page.dart';
import 'package:flutter/material.dart';
import 'package:cocoa_supply/widgets/pages/home_page.dart';
import 'package:cocoa_supply/widgets/pages/login_page.dart';

// Import หน้า Dynamic Register ที่เราสร้างใหม่
import 'package:cocoa_supply/widgets/pages/dynamic_register_page.dart';

/// Class for managing application routing
class AppRoute {
  static const String login = '/';
  static const String home = '/home';
  static const String liffLink = '/liff-link';
  static const String farmRegister = '/farmRegister';
  static const String userRegister = '/userRegister';
  static const String roleRegister = '/roleRegister';
  static const String plotRegister = '/plotRegister';
  static const String hubRegister = '/hubRegister';
  static const String processingStationRegister = '/processingStationRegister';

  // --- Dynamic Routes ---
  static const String dynamicRegister = '/dynamicRegister';
  
  
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // รับ arguments ในรูปแบบ Map
    final args = settings.arguments as Map<String, dynamic>?;
    final path = Uri.parse(settings.name ?? '').path;
    
    switch (path) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case liffLink:
        return MaterialPageRoute(builder: (_) => const LiffLinkPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case userRegister:
        return MaterialPageRoute(builder: (_) => UserRegisterPage());
      case roleRegister:
        return MaterialPageRoute(builder: (_) => RegisterRolePage());
      case farmRegister:
        return MaterialPageRoute(
          builder: (_) => const FarmRegisterPage(),
        );
      case plotRegister:
        // รับค่า farm_id จาก arguments ที่ส่งมาตอน Navigator.push
        final farmId = args?['farm_id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => PlotRegisterPage(farmId: farmId),
        );
      case hubRegister:
        return MaterialPageRoute(
          builder: (_) => HubRegisterPage(),
        );
      case processingStationRegister:
        return MaterialPageRoute(
          builder: (_) => ProcessingStationRegisterPage(),
        );

      // ==========================================
      // DYNAMIC FORM ROUTE
      // ==========================================
      case dynamicRegister:
        if (args != null && args.containsKey('handler')) {
          return MaterialPageRoute(
            builder: (_) => DynamicRegisterPage(
              // handler ในการดึง schema
              handler: args['handler'], 
              
              // taskId สำหรับระบุงาน (UUID จาก Go)
              taskId: args['taskId'],
              
              // status สำหรับเช็กเงื่อนไข (COMPLETED, OVERDUE, PENDING, DRAFT, NOT_STARTED)
              status: args['status'] ?? 'NOT_STARTED',
            ),
          );
        }
        return _errorRoute("กรุณาระบุ tableName สำหรับหน้า Dynamic Register");

      
      default:
        return _errorRoute("ไม่พบเส้นทาง: ${settings.name}");
    }
  }

  /// หน้า Error สำหรับกรณีหา Route ไม่เจอหรือ Arguments ไม่ครบ
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Routing Error")),
        body: Center(child: Text(message, style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
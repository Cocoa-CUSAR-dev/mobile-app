// lib/services/liff_api.dart
import 'package:cocoa_supply/services/liff_service.dart';

/// The LIFF SDK as the link page uses it, behind one object so LiffLoginBloc
/// can be tested without a browser. The real one forwards to liff_service.dart
/// (the browser's SDK on web, an empty stand-in elsewhere).
class LiffApi {
  const LiffApi();

  /// liff.init(), once per page (see liffInit).
  Future<void> init(String liffId) => liffInit(liffId);

  bool get isLoggedIn => liffIsLoggedIn();

  /// null when LIFF has no ID token (not logged in, or no `openid` scope).
  String? get idToken => liffGetIDToken();

  /// Sends the whole page to LINE's login; it comes back with a `code`.
  void login() => liffLogin();
}

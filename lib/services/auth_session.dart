import 'dart:convert';

import 'package:cocoa_supply/config/hub_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// The signed-in session from backend-hub: an access token (sent as
/// `Authorization: Bearer`) and a refresh token, both in the platform
/// keystore/keychain (flutter_secure_storage), never in plain storage.
///
/// The access token lives about an hour. Before each request
/// [freshAccessToken] swaps the refresh token for a new pair when the access
/// token is about to expire, so a farmer stays signed in for as long as they
/// open the app at least once every 90 days (the hub slides that window on
/// every refresh). A refused refresh token signs out.
class AuthSession {
  static const String accessKey = 'auth_token';
  static const String refreshKey = 'refresh_token';

  /// Refresh this long before expiry, so a request that starts just before
  /// the deadline doesn't fail halfway.
  static const Duration refreshMargin = Duration(seconds: 60);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Keep the token pair from any hub login-like response
  /// (`{access_token, refresh_token, ...}`). Returns whether it found one.
  static Future<bool> saveFrom(dynamic body) async {
    if (body is! Map) return false;
    final access = body['access_token'];
    final refresh = body['refresh_token'];
    if (access is! String || access.isEmpty) return false;
    await _storage.write(key: accessKey, value: access);
    if (refresh is String && refresh.isNotEmpty) {
      await _storage.write(key: refreshKey, value: refresh);
    }
    return true;
  }

  static Future<String?> accessToken() => _storage.read(key: accessKey);

  static Future<void> clear() async {
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
  }

  /// Seconds left on a JWT's `exp`, or null if it can't be read. Only "is it
  /// worth sending" -- the server checks the signature.
  static int? secondsLeft(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return null;
      return exp.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  /// The access token to send now, refreshed first if it is about to expire.
  /// Null when signed out (or the hub refused the refresh token).
  static Future<String?> freshAccessToken(http.Client client) async {
    final access = await accessToken();
    final left = access == null ? null : secondsLeft(access);
    if (access != null && (left == null || left > refreshMargin.inSeconds)) {
      // Not a JWT we can read (left == null) or plenty of time left.
      return access;
    }
    return refresh(client);
  }

  /// Swap the refresh token for a new pair. Null (and signed out) if the hub
  /// refuses it; the current token if the hub can't be reached right now.
  static Future<String?> refresh(http.Client client) async {
    final refreshToken = await _storage.read(key: refreshKey);
    if (refreshToken == null || hubBaseUrl.isEmpty) return accessToken();
    try {
      final response = await client
          .post(
            Uri.parse('$hubBaseUrl/api/v1/auth/refresh'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await saveFrom(jsonDecode(utf8.decode(response.bodyBytes)));
        return accessToken();
      }
      if (response.statusCode == 401) {
        await clear();
        return null;
      }
    } catch (_) {
      // Offline: keep the old token; the request decides what happens.
    }
    return accessToken();
  }

  /// Sign out: revoke this device's refresh token at the hub (best effort),
  /// then forget both tokens.
  static Future<void> signOut(http.Client client) async {
    final refreshToken = await _storage.read(key: refreshKey);
    if (refreshToken != null && hubBaseUrl.isNotEmpty) {
      try {
        await client
            .post(
              Uri.parse('$hubBaseUrl/api/v1/auth/logout'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Signing out locally must work even offline.
      }
    }
    await clear();
  }
}

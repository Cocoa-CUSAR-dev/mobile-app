import 'dart:convert';

import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

/// Forgot password: ask backend-hub for a 6-digit code, then send the code
/// with a new password.
///
/// Both answers are empty or bare (202, 204), which ServiceProvider.postData
/// reads as a broken response, and neither call has a session to attach, so
/// this talks to the backend directly. A refusal is a [ServerRejection] whose
/// message is the backend's own Thai text.
class PasswordResetService {
  final http.Client _client;

  PasswordResetService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  /// Asks for a code. The backend answers the same whether or not the account
  /// exists, and sends the code to the email or LINE on the account, if any.
  Future<void> requestCode(String login) => _post(ApiEndpoints.authForgotPassword, {'login': login.trim()});

  /// Sets the new password with the code. Every session of the account ends.
  Future<void> confirm({required String login, required String code, required String newPassword}) => _post(
    ApiEndpoints.authForgotPasswordConfirm,
    {'login': login.trim(), 'code': code.trim(), 'new_password': newPassword},
  );

  Future<void> _post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${apiBaseUrlFor(apiGroupOf(endpoint))}$endpoint');
    final response = await _client
        .post(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: jsonEncode(body))
        .timeout(_timeout);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ServerRejection(response.statusCode, _reasonOf(response));
  }

  /// The backend answers {"detail": "..."}; a request it could not read has a
  /// list there instead, which has no single message to show.
  static String _reasonOf(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {
      // not JSON: fall through
    }
    return 'ส่งคำขอไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
  }
}

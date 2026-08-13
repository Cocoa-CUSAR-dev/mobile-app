// Shared helpers for test/services/*_test.dart.
//
// http.Response's default constructor encodes the body as latin1 when no
// content-type is given, which throws on any non-ASCII text (Thai names,
// notes, etc. are all over this API's payloads). Always build mock JSON
// responses through jsonResponse() so the body is treated as UTF-8.

import 'dart:convert';

import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

http.Response jsonResponse(dynamic data, int statusCode, {Map<String, String>? headers}) {
  return http.Response(
    jsonEncode(data),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
  );
}

/// The API base URL every ServiceProvider defaults to (overridable via
/// --dart-define=API_BASE_URL=...). Read dynamically from ServiceProvider
/// itself rather than hardcoded, so tests asserting on request URLs don't
/// go stale every time the deployed backend's default URL changes.
final String testBaseUrl = ServiceProvider(storageKey: '_probe', endpoint: '').baseUrl;

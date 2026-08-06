// Shared helpers for test/services/*_test.dart.
//
// http.Response's default constructor encodes the body as latin1 when no
// content-type is given, which throws on any non-ASCII text (Thai names,
// notes, etc. are all over this API's payloads). Always build mock JSON
// responses through jsonResponse() so the body is treated as UTF-8.

import 'dart:convert';

import 'package:http/http.dart' as http;

http.Response jsonResponse(dynamic data, int statusCode, {Map<String, String>? headers}) {
  return http.Response(
    jsonEncode(data),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
  );
}

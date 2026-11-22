import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the guided tour keeps on the phone (docs-and-plan#311), in
/// flutter_secure_storage like the session, so it survives an app restart:
/// - the "seen" flag;
/// - a running tour's progress, so closing the app mid-tour doesn't lose it.
class TourService {
  TourService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'tour_seen';
  static const String _progressKey = 'tour_progress';

  Future<bool> hasSeen() async => await _storage.read(key: _key) == 'true';

  Future<void> markSeen() => _storage.write(key: _key, value: 'true');

  Future<void> reset() => _storage.delete(key: _key);

  Future<Map<String, dynamic>?> loadProgress() async {
    final saved = await _storage.read(key: _progressKey);
    if (saved == null) return null;
    try {
      return jsonDecode(saved) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> saveProgress(Map<String, dynamic> progress) =>
      _storage.write(key: _progressKey, value: jsonEncode(progress));

  Future<void> clearProgress() => _storage.delete(key: _progressKey);
}

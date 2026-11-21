import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The guided tour's "seen" flag (docs-and-plan#311). Kept in
/// flutter_secure_storage, like the session, so it survives an app restart.
class TourService {
  TourService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _key = 'tour_seen';

  Future<bool> hasSeen() async => await _storage.read(key: _key) == 'true';

  Future<void> markSeen() => _storage.write(key: _key, value: 'true');

  Future<void> reset() => _storage.delete(key: _key);
}

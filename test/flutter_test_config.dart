// Runs automatically before every test file in this directory (Flutter's
// flutter_test_config.dart convention -- no per-file setUp() needed).
//
// APP-2 moved ServiceProvider off SharedPreferences onto flutter_secure_storage.
// Unlike SharedPreferences, flutter_secure_storage has no platform channel
// registered in a plain `flutter test` environment, so any read/write throws
// MissingPluginException(... plugins.it_nomads.com/flutter_secure_storage)
// unless the platform instance is swapped for the package's own in-memory
// test double first -- mirroring the SharedPreferences.setMockInitialValues({})
// call already present in every test's own setUp().
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // setUp (not a bare call before testMain) so storage resets before EACH
  // test case, not just once per file -- otherwise data written by one test
  // (e.g. a cached API response) leaks into the next test in the same file,
  // same as why SharedPreferences.setMockInitialValues({}) is called from
  // inside every test file's own setUp() rather than once at the top.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  await testMain();
}

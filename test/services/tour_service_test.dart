// The guided tour's "seen" flag (docs-and-plan#311). flutter_test_config.dart
// swaps flutter_secure_storage for its in-memory double before each test.

import 'package:cocoa_supply/services/tour_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new install has not seen the tour', () async {
    expect(await TourService().hasSeen(), isFalse);
  });

  test('markSeen survives a restart (a new TourService reads the same storage)', () async {
    await TourService().markSeen();
    expect(await TourService().hasSeen(), isTrue);
  });

  test('reset clears the flag', () async {
    final service = TourService();
    await service.markSeen();
    await service.reset();
    expect(await service.hasSeen(), isFalse);
  });
}

// Unit tests for lib/services/harvest_grade_detail_service.dart.

import 'package:cocoa_supply/models/harvest_grade_detail_model.dart';
import 'package:cocoa_supply/services/harvest_grade_detail_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getHarvestGradeDetails', () {
    test('returns parsed details on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/harvest_grade_details');
        return jsonResponse([
          {'harvest_id': 1, 'grade_code': 'A'},
          {'harvest_id': 2, 'grade_code': 'B'},
        ], 200);
      });

      final details = await HarvestGradeDetailService(client: client).getHarvestGradeDetails();

      expect(details, hasLength(2));
    });
  });

  group('getDetailsByHarvestId', () {
    test('filters the full list down to the matching harvestId', () async {
      final client = MockClient((request) async {
        return jsonResponse([
          {'harvest_id': 1, 'grade_code': 'A'},
          {'harvest_id': 2, 'grade_code': 'B'},
        ], 200);
      });

      final details = await HarvestGradeDetailService(client: client).getDetailsByHarvestId('2');

      expect(details, hasLength(1));
      expect(details.first.gradeCode, 'B');
    });

    test('returns an empty list when nothing matches', () async {
      final client = MockClient((request) async => jsonResponse([], 200));

      final details = await HarvestGradeDetailService(client: client).getDetailsByHarvestId('missing');

      expect(details, isEmpty);
    });
  });

  group('saveHarvestGradeDetail', () {
    test('posts the detail payload', () async {
      var posted = false;
      final client = MockClient((request) async {
        posted = request.method == 'POST';
        return jsonResponse({}, 200);
      });

      await HarvestGradeDetailService(client: client).saveHarvestGradeDetail(
        HarvestGradeDetail(harvestId: '1', gradeCode: 'A'),
      );

      expect(posted, isTrue);
    });
  });
}

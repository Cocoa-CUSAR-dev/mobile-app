// lib/services/harvest_grade_detail_service.dart
import 'package:cocoa_supply/models/harvest_grade_detail_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

class HarvestGradeDetailService {
  static const String _storageKey = 'grade_detail_data';
  static const String _endpoint = '/harvest_grade_details';

  HarvestGradeDetailService({http.Client? client})
    : _provider = ServiceProvider<HarvestGradeDetail>(
        storageKey: _storageKey,
        endpoint: _endpoint,
        isRealApi: true,
        client: client,
      );

  final ServiceProvider<HarvestGradeDetail> _provider;

  /// ดึงรายละเอียดเกรดทั้งหมด
  Future<List<HarvestGradeDetail>> getHarvestGradeDetails() async {
    return _provider.fetchData(
      HarvestGradeDetail.fromJson,
    );
  }

  /// ดึงรายละเอียดเกรดเฉพาะของการเก็บเกี่ยว (Filter by Harvest ID)
  Future<List<HarvestGradeDetail>> getDetailsByHarvestId(String harvestId) async {
    final all = await getHarvestGradeDetails();
    return all.where((detail) => detail.harvestId == harvestId).toList();
  }

  /// บันทึกรายละเอียดเกรด
  Future<void> saveHarvestGradeDetail(HarvestGradeDetail detail) async {
    await _provider.postData(detail.toJson());
  }
}
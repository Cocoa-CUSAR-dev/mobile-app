import 'package:cocoa_supply/models/batch_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class BatchService {
  final ServiceProvider<Batch> _provider = ServiceProvider<Batch>(
    storageKey: 'batch_data',
    endpoint: '/batchs',
    isRealApi: true,
  );
  Future<List<Batch>> getBatches() async => _provider.fetchData(Batch.fromJson);
}
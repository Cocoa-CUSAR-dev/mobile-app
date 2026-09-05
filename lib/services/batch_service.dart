import 'package:cocoa_supply/models/batch_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

class BatchService {
  BatchService({http.Client? client})
    : _provider = ServiceProvider<Batch>(
        storageKey: 'batch_data',
        endpoint: '/batchs',
        isRealApi: true,
        client: client,
      );

  final ServiceProvider<Batch> _provider;
  Future<List<Batch>> getBatches() async => _provider.fetchData(Batch.fromJson);
}
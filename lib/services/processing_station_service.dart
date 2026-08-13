import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;

class ProcessingStationService {
  ProcessingStationService({http.Client? client})
    : _provider = ServiceProvider<ProcessingStation>(
        storageKey: 'processing_station_data',
        endpoint: '/processing_stations',
        isRealApi: true,
        client: client,
      );

  final ServiceProvider<ProcessingStation> _provider;

  Future<List<ProcessingStation>> getStations() async {
    return _provider.fetchData(ProcessingStation.fromJson);
  } 
  
  Future<void> saveStation(ProcessingStation station) async => _provider.postData(station.toJson());
}
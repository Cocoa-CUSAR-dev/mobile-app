import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';

class ProcessingStationService {
  final ServiceProvider<ProcessingStation> _provider = ServiceProvider<ProcessingStation>(
    storageKey: 'processing_station_data',
    endpoint: '/processing_stations',
    isRealApi: true,
  );

  Future<List<ProcessingStation>> getStations() async {
    return _provider.fetchData(ProcessingStation.fromJson);
  } 
  
  Future<void> saveStation(ProcessingStation station) async => _provider.postData(station.toJson());
}
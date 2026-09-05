import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:cocoa_supply/services/processing_station_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ProcessingStationEvent {}
class LoadProcessingStations extends ProcessingStationEvent {}

// lib/bloc/station/station_state.dart
abstract class ProcessingStationState {}
class ProcessingStationInitial extends ProcessingStationState {}
class ProcessingStationLoading extends ProcessingStationState {}
class ProcessingStationsLoaded extends ProcessingStationState {
  final List<ProcessingStation> stations;
  ProcessingStationsLoaded(this.stations);
}

// lib/bloc/station/station_bloc.dart
class ProcessingStationBloc extends Bloc<ProcessingStationEvent, ProcessingStationState> {
  final ProcessingStationService _stationService;

  ProcessingStationBloc({ProcessingStationService? stationService})
    : _stationService = stationService ?? ProcessingStationService(),
      super(ProcessingStationInitial()) {
    on<LoadProcessingStations>((event, emit) async {
      emit(ProcessingStationLoading());
      try {

        final stations =  await _stationService.getStations();
        emit(ProcessingStationsLoaded(stations));
      } catch (e) { print(e); }
    });
  }
}
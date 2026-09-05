// lib/blocs/hub_bloc.dart
import 'package:cocoa_supply/services/hub_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'hub_event.dart';
import 'hub_state.dart';

class HubBloc extends Bloc<HubEvent, HubState> {
  final HubService _hubService;

  HubBloc({HubService? hubService})
    : _hubService = hubService ?? HubService(),
      super(HubInitial()) {
    on<LoadHubs>(_onLoadHubs);
  }

  Future<void> _onLoadHubs(LoadHubs event, Emitter<HubState> emit) async {
    emit(HubLoading());
    try {
      // ดึงข้อมูล 3 อย่างขนานกันเพื่อความเร็ว
      final results = await _hubService.fetchAll();

      emit(HubsLoaded(hubs: results));
    } catch (e) {
      emit(HubError("โหลดข้อมูลภาพรวมไม่สำเร็จ: ${e.toString()}"));
    }
  }
}
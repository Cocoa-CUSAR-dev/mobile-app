import 'dart:convert';

import 'package:cocoa_supply/bloc/farm/farm_event.dart';
import 'package:cocoa_supply/bloc/farm/farm_state.dart';
import 'package:cocoa_supply/services/farm_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FarmBloc extends Bloc<FarmEvent, FarmState> {
  final FarmService _farmService = FarmService();

  FarmBloc() : super(FarmInitial()) {
    on<LoadFarms>(_onLoadFarms);
  }

  Future<void> _onLoadFarms(LoadFarms event, Emitter<FarmState> emit) async {
    emit(FarmLoading());
    try {
      // โหลดเฉพาะฟาร์ม ไม่ต้องยุ่งกับ PlotService แล้ว
      final farms = await _farmService.getFarms();
      print(jsonEncode(farms));
      emit(FarmsLoaded(farms)); // ปรับ FarmsLoaded ให้รับแค่ List<Farm>
    } catch (e) {
      emit(FarmOperationFailure(e.toString()));
    }
  }
}
// lib/bloc/plot/plot_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'plot_event.dart';
import 'plot_state.dart';
import 'package:cocoa_supply/services/plot_service.dart';

class PlotBloc extends Bloc<PlotEvent, PlotState> {
  final PlotService _service = PlotService();

  PlotBloc() : super(PlotInitial()) {
    on<LoadPlots>(_onLoadPlots);
    on<RegisterPlot>(_onRegisterPlot);
    on<UpdatePlot>(_onUpdatePlot);
    on<DeletePlot>(_onDeletePlot);
  }

  Future<void> _onLoadPlots(LoadPlots event, Emitter<PlotState> emit) async {
    emit(PlotLoading());
    try {
      final plots = await _service.getPlots();
      emit(PlotsLoaded(plots));
    } catch (e) {
      emit(PlotOperationFailure(e.toString()));
    }
  }

  Future<void> _onRegisterPlot(RegisterPlot event, Emitter<PlotState> emit) async {
    emit(PlotLoading());
    try {
      await _service.savePlot(event.plot);
      
      final updatedList = await _service.getPlots();
      emit(PlotRegistrationSuccess(event.plot));
      emit(PlotOperationSuccess(plots: updatedList, message: 'แปลงย่อยภายในฟาร์มถูกบันทึกเรียบร้อย'));
    } catch (e) {
      emit(PlotOperationFailure(e.toString()));
    }
  }

  Future<void> _onUpdatePlot(UpdatePlot event, Emitter<PlotState> emit) async {
    emit(PlotLoading());
    try {
      // await _service.updatePlot(event.plot);
      
      final updatedList = await _service.getPlots();
      emit(PlotOperationSuccess(plots: updatedList, message: 'แปลงย่อยภายในฟาร์มถูกอัปเดตเรียบร้อย'));
    } catch (e) {
      emit(PlotOperationFailure(e.toString()));
    }
  }

  Future<void> _onDeletePlot(DeletePlot event, Emitter<PlotState> emit) async {
    emit(PlotLoading());
    try {
      await _service.deletePlot(event.farmNo);
      
      final updatedList = await _service.getPlots();
      emit(PlotOperationSuccess(plots: updatedList, message: 'แปลงย่อยภายในฟาร์มถูกลบเรียบร้อย'));
    } catch (e) {
      emit(PlotOperationFailure(e.toString()));
    }
  }
}

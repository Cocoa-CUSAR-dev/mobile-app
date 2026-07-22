// lib/bloc/batch/batch_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BatchEvent extends Equatable {
  const BatchEvent();
  @override
  List<Object?> get props => [];
}

class LoadBatchDetail extends BatchEvent {
  final String batchNo;
  final String processingStationNo;
  const LoadBatchDetail(this.batchNo, this.processingStationNo);

  @override
  List<Object?> get props => [batchNo, processingStationNo];
}

abstract class BatchState extends Equatable {
  const BatchState();
  @override
  List<Object?> get props => [];
}

class BatchInitial extends BatchState {}

class BatchLoading extends BatchState {}

class BatchLoaded extends BatchState {
  final List<dynamic> fermentations; // จากตาราง fermentation_batch 
  final List<dynamic> dryings;       // จากตาราง drying_batch 
  final List<dynamic> records; // จากตาราง processing_record 

  const BatchLoaded({
    required this.fermentations,
    required this.dryings,
    required this.records,
  });

  @override
  List<Object?> get props => [fermentations, dryings, records];
}

class BatchOperationFailure extends BatchState {
  final String error;
  const BatchOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class BatchBloc extends Bloc<BatchEvent, BatchState> {
  // ใช้ ServiceProvider แบบ Generic dynamic ไปก่อนตามความต้องการ

  BatchBloc() : super(BatchInitial()) {
    on<LoadBatchDetail>(_onLoadBatchDetail);
  }

  Future<void> _onLoadBatchDetail(LoadBatchDetail event, Emitter<BatchState> emit) async {
    emit(BatchLoading());
    try {
      // ดึงข้อมูล 3 ส่วนพร้อมกันโดยใช้ filter batch_no 
      final List<dynamic> fermentList = [
        {'startedAt': '5 มกราคม 2569'}
      ];

      final List<dynamic> dryingList = [
        {'startedAt': '8 มกราคม 2569'}
      ];

      final List<dynamic> recordList = [
        {
          'recordedAt': '5 มกราคม 2569',
          'tempMorningOutside' : 30
        },
        {
          'recordedAt': '9 มกราคม 2569',
          'tempMorningOutside' : 30
        }
      ];

      emit(BatchLoaded(
        fermentations: fermentList,
        dryings: dryingList,
        records: recordList,
      ));
    } catch (e) {
      emit(BatchOperationFailure(e.toString()));
    }
  }
}
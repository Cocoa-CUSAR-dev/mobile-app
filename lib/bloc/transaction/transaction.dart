// lib/bloc/transaction/transaction_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

class LoadTransactionDetail extends TransactionEvent {
  final String transactionNo;
  const LoadTransactionDetail(this.transactionNo);

  @override
  List<Object?> get props => [transactionNo];
}

// lib/bloc/transaction/transaction_state.dart
abstract class TransactionState extends Equatable {
  const TransactionState();
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<dynamic> transactionDetails; // จากตาราง transaction_detail 
  final List<dynamic> gradeDetails;       // ข้อมูลเกรด เช่น harvest_grade_detail 

  const TransactionLoaded({
    required this.transactionDetails,
    required this.gradeDetails,
  });

  @override
  List<Object?> get props => [transactionDetails, gradeDetails];
}

class TransactionOperationFailure extends TransactionState {
  final String error;
  const TransactionOperationFailure(this.error);
}

// lib/bloc/transaction/transaction_bloc.dart
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<LoadTransactionDetail>(_onLoadTransactionDetail);
  }

  Future<void> _onLoadTransactionDetail(
    LoadTransactionDetail event, Emitter<TransactionState> emit) async {
    emit(TransactionLoading());
    try {
      // Mockup ข้อมูลรายละเอียดธุรกรรม (Transaction Detail) 
      final List<dynamic> detailList = [
        {
          'transaction_detail_no': 'TD-001',
          'price': 450.0,
          'fresh_cacao_weight_kg': 50.5,
          'transaction_date': '2026-01-05',
        }
      ];

      // Mockup ข้อมูลเกรด (Grade Detail) อ้างอิง harvest_grade_detail 
      final List<dynamic> gradeList = [
        {
          'grade_code': 'ผลมีขนาดใหญ่',
          'quantity_kg': 30.0,
          'weight_gram_per_pod': 450,
          'is_clean': true,
        },
        {
          'grade_code': 'เกิดราดำ (ตกเกรด)',
          'quantity_kg': 20.5,
          'weight_gram_per_pod': 380,
          'is_clean': false,
        }
      ];

      emit(TransactionLoaded(
        transactionDetails: detailList,
        gradeDetails: gradeList,
      ));
    } catch (e) {
      emit(TransactionOperationFailure(e.toString()));
    }
  }
}
// Unit tests for lib/bloc/transaction/transaction.dart.
//
// TransactionBloc currently returns hard-coded mock data (no service
// dependency yet), so this pins the emitted-state shape.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/transaction/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionBloc', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] with details and grades',
      build: () => TransactionBloc(),
      act: (bloc) => bloc.add(const LoadTransactionDetail('TD-001')),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionLoaded>()
            .having((s) => s.transactionDetails, 'transactionDetails', hasLength(1))
            .having((s) => s.gradeDetails, 'gradeDetails', hasLength(2)),
      ],
    );
  });
}

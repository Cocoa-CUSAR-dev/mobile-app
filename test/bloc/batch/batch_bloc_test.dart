// Unit tests for lib/bloc/batch/batch.dart.
//
// BatchBloc currently returns hard-coded mock data (no service dependency
// yet), so this pins the emitted-state shape rather than any network path.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/batch/batch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatchBloc', () {
    blocTest<BatchBloc, BatchState>(
      'emits [BatchLoading, BatchLoaded] with the three mocked sections',
      build: () => BatchBloc(),
      act: (bloc) => bloc.add(const LoadBatchDetail('B-001', 'PS-001')),
      expect: () => [
        isA<BatchLoading>(),
        isA<BatchLoaded>()
            .having((s) => s.fermentations, 'fermentations', hasLength(1))
            .having((s) => s.dryings, 'dryings', hasLength(1))
            .having((s) => s.records, 'records', hasLength(2)),
      ],
    );
  });
}

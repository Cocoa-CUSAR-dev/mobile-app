// lib/bloc/farm/farm_state.dart

import 'package:cocoa_supply/models/farm_model.dart';
import 'package:equatable/equatable.dart';

abstract class FarmState extends Equatable {
  const FarmState();
  @override
  List<Object?> get props => [];
}

/// Initial state
class FarmInitial extends FarmState {}

/// State when data fetching or saving is in progress
class FarmLoading extends FarmState {}

/// State when farms have been successfully loaded/fetched
class FarmsLoaded extends FarmState {
  final List<Farm> farms;
  const FarmsLoaded(this.farms);

  @override
  List<Object?> get props => [farms];
}

/// State when a single operation (register, update, delete) is successful
class FarmOperationSuccess extends FarmState {
  final List<Farm>? farms; // Optional list for updated data after operation
  final String? message;
  const FarmOperationSuccess({this.farms, this.message});

  @override
  List<Object?> get props => [farms ?? [], message];
}

/// State when an error occurs
class FarmOperationFailure extends FarmState {
  final String error;
  const FarmOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

/// State when registering a single farm is successful (optional, could use OperationSuccess)
class FarmRegistrationSuccess extends FarmState {
  final Farm newFarm;
  const FarmRegistrationSuccess(this.newFarm);

  @override
  List<Object?> get props => [newFarm];
}

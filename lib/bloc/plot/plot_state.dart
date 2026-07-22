// lib/bloc/plot/plot_state.dart

import 'package:cocoa_supply/models/plot_model.dart';
import 'package:equatable/equatable.dart';

abstract class PlotState extends Equatable {
  const PlotState();
  @override
  List<Object?> get props => [];
}

/// Initial state
class PlotInitial extends PlotState {}

/// State when data fetching or saving is in progress
class PlotLoading extends PlotState {}

/// State when plots have been successfully loaded/fetched
class PlotsLoaded extends PlotState {
  final List<Plot> plots;
  const PlotsLoaded(this.plots);

  @override
  List<Object?> get props => [plots];
}

/// State when a single operation (register, update, delete) is successful
class PlotOperationSuccess extends PlotState {
  final List<Plot>? plots; // Optional list for updated data after operation
  final String? message;
  const PlotOperationSuccess({this.plots, this.message});

  @override
  List<Object?> get props => [plots ?? [], message];
}

/// State when an error occurs
class PlotOperationFailure extends PlotState {
  final String error;
  const PlotOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

/// State when registering a single plot is successful (optional, could use OperationSuccess)
class PlotRegistrationSuccess extends PlotState {
  final Plot newPlot;
  const PlotRegistrationSuccess(this.newPlot);

  @override
  List<Object?> get props => [newPlot];
}

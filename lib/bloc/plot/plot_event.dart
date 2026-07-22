// lib/bloc/plot/plot_event.dart

import 'package:cocoa_supply/models/plot_model.dart';
import 'package:equatable/equatable.dart';

abstract class PlotEvent extends Equatable {
  const PlotEvent();
  @override
  List<Object?> get props => [];
}

/// Event to fetch all existing plots
class LoadPlots extends PlotEvent {}

/// Event to register a new plot
class RegisterPlot extends PlotEvent {
  final Plot plot;
  const RegisterPlot(this.plot);

  @override
  List<Object?> get props => [plot];
}

/// Event to update an existing plot
class UpdatePlot extends PlotEvent {
  final Plot plot;
  const UpdatePlot(this.plot);

  @override
  List<Object?> get props => [plot];
}

/// Event to delete an existing plot
class DeletePlot extends PlotEvent {
  final String farmNo;
  const DeletePlot(this.farmNo);

  @override
  List<Object?> get props => [farmNo];
}

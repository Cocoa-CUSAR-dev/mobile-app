// lib/bloc/farm/farm_event.dart
import 'package:equatable/equatable.dart';

abstract class FarmEvent extends Equatable {
  const FarmEvent();
  @override
  List<Object?> get props => [];
}

/// Event to fetch all existing farms
class LoadFarms extends FarmEvent {}
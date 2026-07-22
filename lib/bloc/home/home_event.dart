import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:equatable/equatable.dart';

// Abstract class สำหรับ Event ในหน้า Home
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class HomeDataRequested extends HomeEvent {
  final DateTime selectedDate;
  HomeDataRequested({required this.selectedDate});
}

class HomeTabChanged extends HomeEvent {
  final int newIndex;
  HomeTabChanged({required this.newIndex});
}

class HomeTaskUpdated extends HomeEvent {
  final List<TaskItem> updatedTasks;
  HomeTaskUpdated(this.updatedTasks);
}
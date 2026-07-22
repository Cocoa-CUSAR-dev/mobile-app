import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:equatable/equatable.dart';

// Abstract class สำหรับ State ในหน้า Home
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object> get props => [];
}

// สถานะเริ่มต้นของหน้า Home
class HomeInitial extends HomeState {
  final int currentTabIndex;
  const HomeInitial({this.currentTabIndex = 0});
  @override
  List<Object> get props => [currentTabIndex];
}

// สถานะเมื่อกำลังโหลดข้อมูลหลัก
class HomeLoading extends HomeState {
  final int currentTabIndex;
  final DateTime selectedDate;
  HomeLoading({
    required this.currentTabIndex,
    required this.selectedDate
  });
  @override
  List<Object> get props => [currentTabIndex];
}

// สถานะเมื่อโหลดข้อมูลหลักสำเร็จ
class HomeLoaded extends HomeState {
  final List<TaskItem> dailyTasks; // เปลี่ยนจาก mock string เป็น List<TaskItem>
  final int currentTabIndex;
  final DateTime selectedDate;

  HomeLoaded({
    required this.dailyTasks,
    required this.currentTabIndex,
    required this.selectedDate,
  });
}

// สถานะเมื่อโหลดข้อมูลหลักล้มเหลว
class HomeLoadFailure extends HomeState {
  final String error;
  const HomeLoadFailure({required this.error});
  @override
  List<Object> get props => [error];
}
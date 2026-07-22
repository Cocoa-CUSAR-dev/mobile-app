import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TaskBloc taskBloc;
  StreamSubscription? _taskSubscription;

  HomeBloc({required this.taskBloc}) : super(HomeInitial(currentTabIndex: 0)) {
    on<HomeDataRequested>(_onHomeDataRequested);
    on<HomeTabChanged>(_onHomeTabChanged);
    on<HomeTaskUpdated>(_onHomeTaskUpdated); // Event ภายในสำหรับอัปเดต UI

    // คอยฟังการเปลี่ยนแปลงจาก TaskBloc
    // เมื่อไหร่ก็ตามที่ TaskBloc เปลี่ยนสถานะ (เช่น Sync เสร็จ) ให้ HomeBloc อัปเดตตาม
    _taskSubscription = taskBloc.stream.listen((taskState) {
      if(!taskState.isLoading) add(HomeTaskUpdated(taskState.tasks));
    });
  }

  Future<void> _onHomeDataRequested(
    HomeDataRequested event,
    Emitter<HomeState> emit,
  ) async {
    int currentIndex = 0;
    if (state is HomeLoaded) currentIndex = (state as HomeLoaded).currentTabIndex;

    emit(HomeLoading(currentTabIndex: currentIndex, selectedDate: event.selectedDate ));
    // สั่งให้ TaskBloc ไป TriggerPendingQueueSync และ ให้ Sync ข้อมูลจาก Server อีกครั้งเพื่อให้ UI เป็นปัจจุบัน ณ วันที่เลือก
    taskBloc.add(TriggerPendingQueueSync(event.selectedDate));
  }

  void _onHomeTabChanged(HomeTabChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final s = state as HomeLoaded;
      emit(HomeLoading(
        currentTabIndex: s.currentTabIndex,
        selectedDate: s.selectedDate
      ));
      // เปลี่ยน Tab ทันที ไม่ต้องผ่าน Loading ให้เสียเวลา
      emit(HomeLoaded(
        dailyTasks: s.dailyTasks,
        currentTabIndex: event.newIndex,
        selectedDate: s.selectedDate,
      ));
    }
  }

  // Event ภายในที่ใช้รับค่าใหม่จาก TaskBloc มาอัปเดตหน้าจอ
  Future<void> _onHomeTaskUpdated(HomeTaskUpdated event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final s = state as HomeLoaded;
      emit(HomeLoading(
        currentTabIndex: s.currentTabIndex,
        selectedDate: s.selectedDate
      ));
      await Future.delayed(Duration.zero);
      emit(HomeLoaded(
        dailyTasks: event.updatedTasks,
        currentTabIndex: s.currentTabIndex,
        selectedDate: s.selectedDate,
      ));
    }else if (state is HomeLoading){
      final s = state as HomeLoading;
      emit(HomeLoaded(
        dailyTasks: event.updatedTasks,
        currentTabIndex: s.currentTabIndex,
        selectedDate: s.selectedDate,
      ));
    }
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel(); // อย่าลืม cancel subscription เมื่อปิด bloc
    return super.close();
  }
}
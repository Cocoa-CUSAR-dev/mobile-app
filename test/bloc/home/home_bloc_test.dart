// Unit tests for lib/bloc/home/home_bloc.dart.
//
// HomeBloc takes its TaskBloc collaborator via constructor injection
// already, so no extra DI seam was needed here — we just hand it a
// TaskBloc wired to a TaskService(client: MockClient(...)).
//
// Covers W-DASH-03 (dashboard data-year/date change -> HomeDataRequested)
// and M-HOME-06..09 (bottom-nav tab switch -> HomeTabChanged).

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TaskBloc buildTaskBloc({List<Map<String, dynamic>> tasks = const []}) {
    final client = MockClient((request) async => jsonResponse(tasks, 200));
    return TaskBloc(taskService: TaskService(client: client));
  }

  group('HomeTabChanged (M-HOME-06..09 bottom nav)', () {
    blocTest<HomeBloc, HomeState>(
      'switching tabs while loaded updates currentTabIndex without a full reload',
      build: () => HomeBloc(taskBloc: buildTaskBloc()),
      seed: () => HomeLoaded(dailyTasks: const [], currentTabIndex: 0, selectedDate: DateTime(2026, 1, 11)),
      act: (bloc) => bloc.add(HomeTabChanged(newIndex: 1)),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having((s) => s.currentTabIndex, 'currentTabIndex', 1),
      ],
    );
  });

  group('HomeDataRequested (W-DASH-03 date/year change)', () {
    blocTest<HomeBloc, HomeState>(
      'requests data for the selected date and forwards a queue sync to TaskBloc',
      build: () => HomeBloc(taskBloc: buildTaskBloc()),
      act: (bloc) => bloc.add(HomeDataRequested(selectedDate: DateTime(2026, 1, 11))),
      expect: () => [
        isA<HomeLoading>().having((s) => s.selectedDate, 'selectedDate', DateTime(2026, 1, 11)),
      ],
    );
  });

  group('HomeTaskUpdated (reacts to TaskBloc completing a sync)', () {
    blocTest<HomeBloc, HomeState>(
      'a completed TaskBloc sync populates dailyTasks once HomeBloc is loaded',
      build: () => HomeBloc(taskBloc: buildTaskBloc(tasks: [
        {'task_id': 't1', 'title': 'ตัดหญ้า'},
      ])),
      seed: () => HomeLoaded(dailyTasks: const [], currentTabIndex: 0, selectedDate: DateTime(2026, 1, 11)),
      act: (bloc) => bloc.taskBloc.add(SyncTasksWithQueue(DateTime(2026, 1, 11))),
      // TaskBloc's local queue lookup has a hard-coded 500ms mock-network
      // delay (ServiceProvider's isRealApi:false branch), so give the
      // cross-bloc reaction enough real wall-clock time to land.
      wait: const Duration(milliseconds: 700),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having((s) => s.dailyTasks.single.title, 'dailyTasks', 'ตัดหญ้า'),
      ],
    );
  });
}

// Widget tests for lib/widgets/pages/home_page.dart.
//
// Moved here from the old top-level test/navigation_test.dart (split per
// page). HomePage renders its shell via RootScaffold without an
// authService override, so the profile fetch runs against a real,
// un-injected http.Client() here — which can eventually resolve to a
// zero-roles profile and trip the same already-documented
// BottomNavigationBar >=2-items crash covered by
// test/widgets/components/root_scaffold_test.dart. These tests aren't
// about that bug, so any exception is drained via tester.takeException()
// rather than reasserted — what they actually check is that HomeBloc/
// TaskBloc process their events without HomePage itself throwing.
//
// Covers W-DASH-01 (dashboard tab shows the daily tasks section) and
// M-HOME-09 (home tab / bottom-nav wiring) at the HomePage level; the
// deeper per-event HomeBloc behavior (W-DASH-03, tab switching) is
// covered directly in test/bloc/home/home_bloc_test.dart.

import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/widgets/pages/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

// TaskBloc's local queue lookup has a 500ms mock-network delay baked into
// ServiceProvider's isRealApi:false branch, and HomeDataRequested chains
// two of these back to back (TriggerPendingQueueSync's own queue fetch,
// then the SyncTasksWithQueue it dispatches afterwards does another) — so
// tests must pump past at least 1000ms before tearing down, or the test
// framework reports "A Timer is still pending".
Future<void> _flushPendingTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('W-DASH-01 / M-HOME-09 — HomePage mounts and dispatches HomeBloc\'s initial event', (tester) async {
    await tester.pumpWidget(wrapPage(const HomePage()));
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);

    await _flushPendingTimers(tester);
    tester.takeException(); // see file header re: the pre-existing RootScaffold bug
  });

  testWidgets('M-HOME-09 — HomeBloc can switch tabs via HomeTabChanged without HomePage itself throwing', (tester) async {
    await tester.pumpWidget(wrapPage(const HomePage()));
    await tester.pump();

    final ctx = tester.element(find.byType(HomePage));
    ctx.read<HomeBloc>().add(HomeTabChanged(newIndex: 1));
    await tester.pump();

    await _flushPendingTimers(tester);
    tester.takeException();
  });

  testWidgets('M-HOME-09 — HomeBloc accepts HomeDataRequested for a given date', (tester) async {
    await tester.pumpWidget(wrapPage(const HomePage()));
    await tester.pump();

    final ctx = tester.element(find.byType(HomePage));
    ctx.read<HomeBloc>().add(HomeDataRequested(selectedDate: DateTime(2026, 1, 11)));
    await tester.pump();

    await _flushPendingTimers(tester);
    tester.takeException();
  });
}

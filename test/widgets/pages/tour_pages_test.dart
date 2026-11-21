// The guided tour's steps after sign-up (docs-and-plan#313): the role page,
// the home page (date, tasks, profile, ฟาร์ม tab) and the farm tab's
// "เพิ่มข้อมูลฟาร์ม" button.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/services/profile_service.dart';
import 'package:cocoa_supply/services/tour_controller.dart';
import 'package:cocoa_supply/widgets/components/root_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/farm_page.dart';
import 'package:cocoa_supply/widgets/pages/home_page.dart';
import 'package:cocoa_supply/widgets/pages/register_role_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';
import 'page_test_helpers.dart';

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TourController.debugReset();
  });

  Future<void> next(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('role page', () {
    testWidgets('after sign-up the farmer taps เกษตรกร, then ถัดไป, for real', (tester) async {
      await TourController.instance.startForNewUser();
      await tester.pumpWidget(wrapPage(const RegisterRolePage()));
      await tester.pumpAndSettle();

      expect(find.text('1/7 · เลือกบทบาทของคุณ'), findsOneWidget);
      expect(find.text('ถัดไป'), findsOneWidget); // only the page's own button
      await tester.tap(find.text('เกษตรกร'));
      await tester.pumpAndSettle();

      expect(find.text('2/7 · ไปต่อ'), findsOneWidget);
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ไปต่อ'), findsNothing);
      expect(find.textContaining('หน้า 1 จาก'), findsOneWidget); // the farmer's form opened
      expect(TourController.instance.isActive, isTrue);
      expect(TourController.instance.wants(TourStage.home), isTrue);
    });

    testWidgets('adding a role from the profile sheet shows no tour', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const RegisterRolePage(ownedRoles: {'farmer'})));
      await tester.pumpAndSettle();

      expect(find.textContaining('เลือกบทบาทของคุณ'), findsNothing);
    });
  });

  group('home page', () {
    late _MockHomeBloc homeBloc;

    setUp(() {
      homeBloc = _MockHomeBloc();
      whenListen(
        homeBloc,
        const Stream<HomeState>.empty(),
        initialState: HomeLoaded(dailyTasks: const [], currentTabIndex: 0, selectedDate: DateTime(2026, 11, 10)),
      );
    });

    Future<void> pumpFarmerHome(WidgetTester tester) async {
      final client = MockClient((request) async => jsonResponse({
        'first_name': 'สมชาย',
        'last_name': 'โกโก้ดี',
        'roles': ['farmer'],
      }, 200));
      await tester.pumpWidget(BlocProvider<HomeBloc>.value(
        value: homeBloc,
        child: MaterialApp(
          home: RootScaffold(
            title: 'หน้าหลัก',
            currentIndex: 0,
            onItemSelected: (_) {},
            authService: AuthService(client: client),
            children: const [HomeTabContent(), Text('farm body')],
          ),
        ),
      ));
      for (var i = 0; i < 30 && find.byType(ThreeDotsLoading).evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('วิธีใช้แอป walks through date, tasks, profile and ends on the ฟาร์ม tab', (tester) async {
      await pumpFarmerHome(tester);
      expect(find.textContaining('เลือกวัน'), findsNothing); // a normal login: no tour

      await tester.tap(find.byIcon(Icons.account_circle).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('วิธีใช้แอป'));
      await tester.tap(find.text('วิธีใช้แอป'));
      await tester.pumpAndSettle();

      expect(find.text('1/5 · เลือกวัน'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.textContaining('งานที่ต้องบันทึก'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('3/5 · โปรไฟล์ของคุณ'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('4/5 · ฟาร์มและแปลงของคุณ'), findsOneWidget);
      expect(find.text('เข้าใจแล้ว'), findsNothing); // tap the tab itself

      await tester.tap(find.byIcon(Icons.park));
      await tester.pumpAndSettle();

      expect(find.textContaining('ฟาร์มและแปลงของคุณ'), findsNothing);
      expect(find.text('farm body'), findsOneWidget);
      expect(TourController.instance.wants(TourStage.farmTab), isTrue);
    });
  });

  group('farm tab', () {
    testWidgets('once the home steps are done, tapping เพิ่มข้อมูลฟาร์ม opens the register page', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
      await tester.pumpAndSettle();

      expect(find.text('5/5 · ลงทะเบียนฟาร์ม'), findsOneWidget);
      await tester.tap(find.text('เพิ่มข้อมูลฟาร์ม'));
      await tester.pumpAndSettle();

      expect(find.text('ลงทะเบียนข้อมูลฟาร์ม'), findsOneWidget);
      // The step closed instead of staying on top of the register page.
      expect(find.textContaining('ลงทะเบียนฟาร์ม'), findsNothing);
      expect(find.text('ข้าม'), findsNothing);
      expect(TourController.instance.wants(TourStage.farm), isTrue);
    });

    testWidgets('no tour running: no step', (tester) async {
      await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
      await tester.pumpAndSettle();

      expect(find.textContaining('ลงทะเบียนฟาร์ม'), findsNothing);
    });
  });
}

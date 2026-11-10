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
    testWidgets('after sign-up the tour explains roles, then the ถัดไป button', (tester) async {
      await TourController.instance.startForNewUser();
      await tester.pumpWidget(wrapPage(const RegisterRolePage()));
      await tester.pumpAndSettle();

      expect(find.text('เลือกบทบาทของคุณ'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('ไปต่อ'), findsOneWidget);
      await next(tester, 'เข้าใจแล้ว');

      expect(find.text('ไปต่อ'), findsNothing);
      expect(TourController.instance.isActive, isTrue);
      expect(TourController.instance.wants(TourStage.home), isTrue);
    });

    testWidgets('adding a role from the profile sheet shows no tour', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const RegisterRolePage(ownedRoles: {'farmer'})));
      await tester.pumpAndSettle();

      expect(find.text('เลือกบทบาทของคุณ'), findsNothing);
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
      expect(find.text('เลือกวัน'), findsNothing); // a normal login: no tour

      await tester.tap(find.byIcon(Icons.account_circle).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('วิธีใช้แอป'));
      await tester.tap(find.text('วิธีใช้แอป'));
      await tester.pumpAndSettle();

      expect(find.text('เลือกวัน'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.textContaining('งานที่ต้องบันทึก'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('โปรไฟล์ของคุณ'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('ฟาร์มและแปลงของคุณ'), findsOneWidget);
      await next(tester, 'เข้าใจแล้ว');

      expect(find.text('ฟาร์มและแปลงของคุณ'), findsNothing);
      expect(TourController.instance.wants(TourStage.farmTab), isTrue);
    });
  });

  group('farm tab', () {
    testWidgets('once the home steps are done, it points at เพิ่มข้อมูลฟาร์ม', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
      await tester.pumpAndSettle();

      expect(find.text('ลงทะเบียนฟาร์ม'), findsOneWidget);
      await next(tester, 'เข้าใจแล้ว');
      expect(find.text('ลงทะเบียนฟาร์ม'), findsNothing);
      expect(TourController.instance.wants(TourStage.farm), isTrue);
    });

    testWidgets('no tour running: no step', (tester) async {
      await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
      await tester.pumpAndSettle();

      expect(find.text('ลงทะเบียนฟาร์ม'), findsNothing);
    });
  });
}

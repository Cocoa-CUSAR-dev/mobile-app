// The guided tour's steps after sign-up (docs-and-plan#313): the role page,
// the home page (date, tasks, profile, ฟาร์ม tab) and the farm tab's
// "เพิ่มข้อมูลฟาร์ม" button.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/services/profile_service.dart';
import 'package:cocoa_supply/services/tour_controller.dart';
import 'package:cocoa_supply/services/tour_service.dart';
import 'package:cocoa_supply/widgets/components/root_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/farm_page.dart';
import 'package:cocoa_supply/widgets/pages/farm_register_page.dart';
import 'package:cocoa_supply/widgets/pages/plot_register_page.dart';
import 'package:cocoa_supply/widgets/pages/home_page.dart';
import 'package:cocoa_supply/widgets/pages/login_page.dart';
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

  group('sign-up (docs-and-plan#312)', () {
    Future<void> openSignUp(WidgetTester tester) async {
      await tester.pumpWidget(wrapPage(const LoginPage()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('สมัครใช้งาน'));
      await tester.tap(find.text('สมัครใช้งาน'));
      await tester.pumpAndSettle();
    }

    testWidgets('สมัครใช้งาน starts the tour, and each field is filled in during its step', (tester) async {
      await openSignUp(tester);
      final fields = find.byType(TextField);

      expect(find.text('1/18 · เบอร์โทรศัพท์'), findsOneWidget);
      await tester.enterText(fields.at(0), '0812345678');
      await tester.pump();
      expect(find.text('0812345678'), findsOneWidget);
      expect(find.text('1/18 · เบอร์โทรศัพท์'), findsOneWidget); // still on this step
      await next(tester, 'ถัดไป');

      expect(find.text('2/18 · ตั้งรหัสผ่าน'), findsOneWidget);
      await tester.enterText(fields.at(1), 'abc123');
      await tester.enterText(fields.at(2), 'abc123');
      await tester.pump();
      expect(find.text('รหัสผ่านตรงกัน'), findsOneWidget);
      await next(tester, 'ถัดไป');

      expect(find.text('3/18 · อีเมล (ไม่บังคับ)'), findsOneWidget);
      await next(tester, 'ถัดไป');

      expect(find.text('4/18 · ไปเลือกบทบาท'), findsOneWidget);
      expect(find.text('เข้าใจแล้ว'), findsNothing); // press the real button
    });

    testWidgets('the last step presses the real button; a wrong field still shows why', (tester) async {
      await openSignUp(tester);
      for (var i = 0; i < 3; i++) {
        await next(tester, 'ถัดไป');
      }

      await tester.tap(find.text('ถัดไป: เลือกบทบาท'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ไปเลือกบทบาท ·'), findsNothing);
      expect(find.text('กรุณาระบุเบอร์โทรศัพท์'), findsOneWidget); // nothing was typed
      // The tour waits for the role page, once the account is made.
      expect(TourController.instance.wants(TourStage.role), isTrue);
    });

    testWidgets('a phone that has seen the tour signs up without it', (tester) async {
      await TourService().markSeen();
      await openSignUp(tester);

      expect(find.text('สร้างบัญชี'), findsOneWidget);
      expect(find.textContaining('เบอร์มือถือ 10 หลัก'), findsNothing);
      expect(TourController.instance.isActive, isFalse);
    });

    testWidgets('logging in never starts the tour', (tester) async {
      await tester.pumpWidget(wrapPage(const LoginPage()));
      await tester.pumpAndSettle();

      expect(TourController.instance.isActive, isFalse);
    });
  });

  group('role page', () {
    testWidgets('after sign-up the farmer taps เกษตรกร, then ถัดไป, for real', (tester) async {
      await TourController.instance.startForNewUser();
      await tester.pumpWidget(wrapPage(const RegisterRolePage()));
      await tester.pumpAndSettle();

      expect(find.text('5/18 · เลือกบทบาทของคุณ'), findsOneWidget);
      expect(find.text('ถัดไป'), findsOneWidget); // only the page's own button
      await tester.tap(find.text('เกษตรกร'));
      await tester.pumpAndSettle();

      expect(find.text('6/18 · ไปต่อ'), findsOneWidget);
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

      expect(find.text('1/12 · เลือกวัน'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.textContaining('งานที่ต้องบันทึก'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('3/12 · โปรไฟล์ของคุณ'), findsOneWidget);
      await next(tester, 'ถัดไป');
      expect(find.text('4/12 · ฟาร์มและแปลงของคุณ'), findsOneWidget);
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

      expect(find.text('5/12 · ลงทะเบียนฟาร์ม'), findsOneWidget);
      await tester.tap(find.text('เพิ่มข้อมูลฟาร์ม'));
      await tester.pumpAndSettle();

      expect(find.text('ลงทะเบียนข้อมูลฟาร์ม'), findsOneWidget);
      // The step closed instead of staying on top of the register page,
      // which shows its own first step.
      expect(find.textContaining('ลงทะเบียนฟาร์ม'), findsNothing);
      expect(find.text('6/12 · ข้อมูลฟาร์ม'), findsOneWidget);
    });

    testWidgets('no tour running: no step', (tester) async {
      await tester.pumpWidget(wrapPage(const FarmPage(), client: emptyMockClient()));
      await tester.pumpAndSettle();

      expect(find.textContaining('ลงทะเบียนฟาร์ม'), findsNothing);
    });
  });

  group('farm and plot (docs-and-plan#314)', () {
    final oneFarm = MockClient((request) async => jsonResponse([
          {'farm_id': 1, 'farm_name': 'สวนโกโก้', 'plots': []},
        ], 200));

    Future<void> openFarmForm(WidgetTester tester) async {
      await tester.pumpWidget(wrapPage(const FarmRegisterPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('the farm form explains its first page, then gets out of the way', (tester) async {
      TourController.instance.replay();
      await openFarmForm(tester);

      expect(find.text('6/12 · ข้อมูลฟาร์ม'), findsOneWidget);
      await next(tester, 'เข้าใจแล้ว');

      expect(find.textContaining('ข้อมูลฟาร์ม ·'), findsNothing);
      expect(find.textContaining('ชื่อฟาร์ม'), findsWidgets); // the page itself, ready to fill
      expect(TourController.instance.isActive, isTrue);
    });

    testWidgets('a farm list before the farm form shows the farm-tab step, not the plot step', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const FarmPage(), client: oneFarm));
      await tester.pumpAndSettle();

      expect(find.text('5/12 · ลงทะเบียนฟาร์ม'), findsOneWidget);
      expect(find.text('9/12 · เพิ่มแปลงปลูก'), findsNothing);
    });

    testWidgets('after the farm form: tap the plots box to add a plot, then the plot form explains itself', (tester) async {
      TourController.instance.replay();
      await openFarmForm(tester);
      await next(tester, 'เข้าใจแล้ว'); // 6/12, the farm form was reached

      await tester.pumpWidget(wrapPage(const FarmPage(), client: oneFarm));
      await tester.pumpAndSettle();
      expect(find.text('9/12 · เพิ่มแปลงปลูก'), findsOneWidget);
      expect(find.text('เข้าใจแล้ว'), findsNothing); // tap the box itself

      await tester.tap(find.text('ใส่ข้อมูล'));
      await tester.pumpAndSettle();

      expect(find.text('ข้อมูลแปลงปลูกโกโก้'), findsOneWidget); // the plot form opened
      expect(find.text('10/12 · ข้อมูลแปลง'), findsOneWidget);
    });

    testWidgets('back on the farm list after the plot form: the last step marks the tour seen', (tester) async {
      TourController.instance.replay();
      await tester.pumpWidget(wrapPage(const PlotRegisterPage(farmId: '1')));
      await tester.pumpAndSettle();
      await next(tester, 'เข้าใจแล้ว'); // 10/12, the plot form was reached

      await tester.pumpWidget(wrapPage(const FarmPage(), client: oneFarm));
      await tester.pumpAndSettle();
      expect(find.text('12/12 · เรียบร้อยแล้ว'), findsOneWidget);
      expect(find.textContaining('วิธีใช้แอป'), findsOneWidget);

      await next(tester, 'เข้าใจแล้ว');
      expect(TourController.instance.isActive, isFalse);
      expect(await TourService().hasSeen(), isTrue);
    });
  });
}

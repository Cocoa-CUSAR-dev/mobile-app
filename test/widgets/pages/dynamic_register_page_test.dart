// Widget tests for lib/widgets/pages/dynamic_register_page.dart.
//
// DynamicBloc now loads its form definition live from the backend
// (GET /tasks/:taskId/form) instead of reading assets/schema.json, so
// unlike before this page can be fully exercised through the MockClient
// DI seam — no more rootBundle-inside-a-Bloc-handler environment
// limitation. The shared client also has to answer TaskService's
// GET /tasks/:taskId (fired by TaskBloc.GetTaskResponseDetails, which
// DynamicBloc's LoadSchemaAndData dispatches) with something harmless.
//
// TaskBloc's local queue lookup has a real 500ms mock-network delay
// (ServiceProvider's isRealApi:false branch), which pumpAndSettle()
// doesn't wait out on its own (no animated widget keeps scheduling
// frames once the spinner is gone) — every test flushes it explicitly
// afterwards so the framework doesn't report "A Timer is still pending".

import 'dart:convert';

import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/dynamic_register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';
import 'page_test_helpers.dart';

http.Client _formClient(Map<String, dynamic> form) {
  return MockClient((request) async {
    if (request.url.path.endsWith('/form')) {
      return jsonResponse({'form': form}, 200);
    }
    return http.Response('', 404);
  });
}

Map<String, dynamic> _formWith(List<Map<String, dynamic>> questions) => {
  'sections': [
    {'isActive': true, 'sortOrder': 1, 'questions': questions},
  ],
};

Future<void> _flushPendingTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('fetches the task form and shows its first field', (tester) async {
    final client = _formClient(_formWith([
      {'fieldName': 'first_name', 'label': 'ชื่อจริง', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
      {'fieldName': 'nickname', 'label': 'ชื่อเล่น', 'inputType': 'VARCHAR', 'isMandatory': false, 'isActive': true, 'sortOrder': 2},
    ]));

    // MockClient resolves near-instantly (no artificial delay like
    // TaskBloc's mock-mode branch elsewhere in this suite), so the
    // DynamicLoading/ThreeDotsLoading frame is too narrow to reliably
    // catch with a pump() — this only asserts the settled result.
    await tester.pumpWidget(wrapPage(
      const DynamicRegisterPage(handler: 'farmer', taskId: 't1', status: 'NOT_STARTED'),
      client: client,
    ));
    await tester.pumpAndSettle();
    await _flushPendingTimers(tester);

    expect(find.text('หน้า 1 จาก 2'), findsOneWidget);
    expect(find.text('ชื่อจริง *', findRichText: true), findsOneWidget);
  });

  testWidgets('"ถัดไป" is disabled until the required field is filled, then advances to step 2', (tester) async {
    final client = _formClient(_formWith([
      {'fieldName': 'first_name', 'label': 'ชื่อจริง', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
      {'fieldName': 'nickname', 'label': 'ชื่อเล่น', 'inputType': 'VARCHAR', 'isMandatory': false, 'isActive': true, 'sortOrder': 2},
    ]));

    await tester.pumpWidget(wrapPage(
      const DynamicRegisterPage(handler: 'farmer', taskId: 't1', status: 'NOT_STARTED'),
      client: client,
    ));
    await tester.pumpAndSettle();

    ElevatedButton nextButton() => tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));
    expect(nextButton().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'สมชาย');
    await tester.pump();
    expect(nextButton().onPressed, isNotNull);

    await tester.tap(find.text('ถัดไป'));
    await tester.pumpAndSettle();
    await _flushPendingTimers(tester);

    expect(find.text('หน้า 2 จาก 2'), findsOneWidget);
  });

  testWidgets('a fetch failure with nothing cached shows the error message instead of a form', (tester) async {
    final client = MockClient((request) async => throw Exception('offline'));

    await tester.pumpWidget(wrapPage(
      const DynamicRegisterPage(handler: 'farmer', taskId: 't1', status: 'NOT_STARTED'),
      client: client,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ThreeDotsLoading), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  // Step 5 checklist: save a draft twice, reopen -> the LATER draft shows.
  // A draft needn't pass validation (the required field is left empty on
  // the first save) and never goes to the server (the client 404s
  // everything but the form).
  testWidgets('"บันทึกแบบร่าง" keeps only the latest draft and reopening restores it', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final client = _formClient(_formWith([
      {'fieldName': 'notes', 'label': 'หมายเหตุ', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
      {'fieldName': 'extra', 'label': 'อื่นๆ', 'inputType': 'VARCHAR', 'isMandatory': false, 'isActive': true, 'sortOrder': 2},
    ]));

    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DynamicRegisterPage(handler: 'farm_activity', taskId: 't1', status: 'NOT_STARTED'),
            ),
          ),
          child: const Text('open'),
        ),
      ),
      client: client,
    ));

    Future<void> saveDraft(String notes) async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _flushPendingTimers(tester);
      await tester.enterText(find.byType(TextFormField).first, notes);
      await tester.tap(find.text('บันทึกแบบร่าง'));
      await tester.pumpAndSettle();
      await _flushPendingTimers(tester);
    }

    await saveDraft('draft 1');
    expect(find.text('open'), findsOneWidget, reason: 'saving a draft closes the form');
    await saveDraft('draft 2');

    final queue = jsonDecode((await const FlutterSecureStorage().read(key: 'pending_task_queue'))!) as List;
    expect(queue, hasLength(1));
    expect(queue.single['status'], 'DRAFT');
    expect(queue.single['answer']['notes'], 'draft 2');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _flushPendingTimers(tester);
    expect(find.widgetWithText(TextFormField, 'draft 2'), findsOneWidget);
  });

  testWidgets('back button (ยกเลิก) on step 1 pops the page', (tester) async {
    final client = _formClient(_formWith([
      {'fieldName': 'first_name', 'label': 'ชื่อจริง', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
    ]));

    await tester.pumpWidget(wrapPage(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DynamicRegisterPage(handler: 'farmer', taskId: 't1', status: 'NOT_STARTED'),
            ),
          ),
          child: const Text('open'),
        ),
      ),
      client: client,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _flushPendingTimers(tester);

    expect(find.text('ชื่อจริง *', findRichText: true), findsOneWidget);

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('ชื่อจริง *', findRichText: true), findsNothing);
  });

  // US2-5: the "ใช้ข้อมูลเดิม?" offer on the real page. Which openings get an
  // offer is DynamicBloc's job (tested per row in dynamic_bloc_test.dart);
  // these check what the farmer sees and what each answer does to the form.
  group('US2-5 autofill offer', () {
    final form = _formWith([
      {
        'fieldName': 'plot_id', 'label': 'แปลงที่ดำเนินการ', 'inputType': 'OPTION',
        'isMandatory': true, 'isActive': true, 'sortOrder': 1,
        'choices': [{'id': 'plot-a', 'name': 'แปลง A'}, {'id': 'plot-b', 'name': 'แปลง B'}],
      },
      {'fieldName': 'description', 'label': 'รายละเอียด', 'inputType': 'VARCHAR', 'isMandatory': false, 'isActive': true, 'sortOrder': 2},
    ]);
    const offer = {
      'submitted_at': '2026-09-30T08:12:00Z',
      'answer': {'plot_id': 'plot-a', 'description': 'ฉีดพ่นรอบโคน'},
    };

    late List<http.Request> requests;

    http.Client client({Map<String, dynamic>? autofill}) => MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/form')) return jsonResponse({'form': form}, 200);
      if (request.url.path.endsWith('/autofill')) {
        return autofill == null ? http.Response('', 204) : jsonResponse(autofill, 200);
      }
      return http.Response('', 404);
    });

    Future<void> openPage(WidgetTester tester, http.Client client) async {
      requests = [];
      FlutterSecureStorage.setMockInitialValues({});
      await tester.pumpWidget(wrapPage(
        const DynamicRegisterPage(handler: 'farm_activity', taskId: 't1', status: 'NOT_STARTED'),
        client: client,
      ));
      await tester.pumpAndSettle();
      // The local queue check (500ms mock delay) runs before the offer is
      // fetched, then the sheet animates in.
      await _flushPendingTimers(tester);
      await tester.pumpAndSettle();
    }

    // The plot question renders every choice as a chip (10 or fewer), so the
    // choice's text is always on screen -- the selection is the widget's value.
    Object? selectedPlot(WidgetTester tester) => tester
        .widget<DropdownInput>(find.byWidgetPredicate((w) => w is DropdownInput && w.label == 'แปลงที่ดำเนินการ'))
        .value;

    ElevatedButton nextButton(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'ถัดไป'));

    testWidgets('accepting fills the form -- OPTION by its name -- still editable, nothing submitted', (tester) async {
      requests = [];
      await openPage(tester, client(autofill: offer));

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsOneWidget);
      expect(find.text('แปลงที่ดำเนินการ: แปลง A'), findsOneWidget, reason: 'preview shows names, not ids');
      expect(find.textContaining('plot-a'), findsNothing);

      await tester.tap(find.text('ใช้ข้อมูลเดิม'));
      await tester.pumpAndSettle();

      // Page 1: the OPTION shows the right choice, and the required field
      // being filled is what enables "ถัดไป".
      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(selectedPlot(tester), 'plot-a');
      expect(nextButton(tester).onPressed, isNotNull);

      // Page 2: the free text is filled -- and still editable.
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'ฉีดพ่นรอบโคน'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'แก้แล้ว');
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'แก้แล้ว'), findsOneWidget);

      // Accepting only filled the form: no submission reached the server.
      expect(requests.where((r) => r.method != 'GET'), isEmpty);
      await _flushPendingTimers(tester);
    });

    testWidgets('"เริ่มใหม่" leaves the form blank', (tester) async {
      await openPage(tester, client(autofill: offer));

      await tester.tap(find.text('เริ่มใหม่'));
      await tester.pumpAndSettle();

      expect(selectedPlot(tester), isNull);
      expect(nextButton(tester).onPressed, isNull, reason: 'the required OPTION is still empty');
      await _flushPendingTimers(tester);
    });

    testWidgets('dismissing the sheet counts as เริ่มใหม่', (tester) async {
      await openPage(tester, client(autofill: offer));

      await tester.tapAt(const Offset(10, 10)); // the barrier above the sheet
      await tester.pumpAndSettle();

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(selectedPlot(tester), isNull);
      await _flushPendingTimers(tester);
    });

    testWidgets('nothing to offer (204) -- no sheet, the form opens as before', (tester) async {
      await openPage(tester, client());

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(find.text('แปลงที่ดำเนินการ *', findRichText: true), findsOneWidget);
      await _flushPendingTimers(tester);
    });
  });
}

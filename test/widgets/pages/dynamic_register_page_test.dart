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

    testWidgets('"เริ่มใหม่" leaves the form blank -- but keeps the offer in the banner', (tester) async {
      await openPage(tester, client(autofill: offer));

      await tester.tap(find.text('เริ่มใหม่'));
      await tester.pumpAndSettle();

      expect(selectedPlot(tester), isNull);
      expect(nextButton(tester).onPressed, isNull, reason: 'the required OPTION is still empty');
      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsOneWidget, reason: 'in case they change their mind');
      await _flushPendingTimers(tester);
    });

    testWidgets('closing the sheet (tap outside) also keeps the offer in the banner', (tester) async {
      await openPage(tester, client(autofill: offer));

      await tester.tapAt(const Offset(10, 10)); // the barrier above the sheet
      await tester.pumpAndSettle();

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(selectedPlot(tester), isNull);
      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsOneWidget);
      await _flushPendingTimers(tester);
    });

    testWidgets('changing your mind: close it, then use it from the banner', (tester) async {
      await openPage(tester, client(autofill: offer));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ใช้ข้อมูลเดิม'));
      await tester.pumpAndSettle();

      expect(selectedPlot(tester), 'plot-a');
      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsNothing, reason: 'used -> gone');
      await _flushPendingTimers(tester);
    });

    testWidgets('nothing to offer (204) -- no sheet, the form opens as before', (tester) async {
      await openPage(tester, client());

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(find.text('แปลงที่ดำเนินการ *', findRichText: true), findsOneWidget);
      await _flushPendingTimers(tester);
    });
  });

  // The page used to close the moment the answer was handed over, before it
  // was sent. It now shows what really happened.
  group('after submitting', () {
    final oneQuestion = _formWith([
      {'fieldName': 'notes', 'label': 'หมายเหตุ', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
    ]);

    http.Client clientAnsweringSubmitWith(Future<http.Response> Function() submit) =>
        MockClient((request) async {
          if (request.method == 'POST') return submit();
          if (request.url.path.endsWith('/form')) return jsonResponse({'form': oneQuestion}, 200);
          return http.Response('', 404);
        });

    Future<void> submitNotes(WidgetTester tester, http.Client client) async {
      FlutterSecureStorage.setMockInitialValues({});
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
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _flushPendingTimers(tester);
      await tester.enterText(find.byType(TextFormField).first, 'ฝนตก');
      await tester.pump();
      await tester.tap(find.text('บันทึกข้อมูล').last);
      await tester.pump();
      // the send, then the local queue write (500ms simulated delay)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    }

    testWidgets('sent -> "บันทึกสำเร็จ", and the button goes back to the task list', (tester) async {
      await submitNotes(tester, clientAnsweringSubmitWith(() async => jsonResponse({}, 201)));

      expect(find.text('บันทึกสำเร็จ'), findsOneWidget);
      await tester.tap(find.text('กลับหน้ารายการงาน'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      await _flushPendingTimers(tester);
    });

    testWidgets('offline -> "ส่งไม่สำเร็จ", and says the answer is kept on the phone', (tester) async {
      await submitNotes(
        tester,
        clientAnsweringSubmitWith(() async => throw http.ClientException('no network')),
      );

      expect(find.text('ส่งไม่สำเร็จ'), findsOneWidget);
      expect(find.textContaining('บันทึกไว้ในเครื่องแล้ว'), findsOneWidget);
      await _flushPendingTimers(tester);
    });

    testWidgets('the server says no -> "ส่งไม่สำเร็จ" with the server\'s reason', (tester) async {
      await submitNotes(
        tester,
        clientAnsweringSubmitWith(() async => jsonResponse({'error': 'ข้อมูลไม่ผ่านการตรวจสอบ'}, 400)),
      );

      expect(find.text('ส่งไม่สำเร็จ'), findsOneWidget);
      expect(find.text('เหตุผลจากระบบ: ข้อมูลไม่ผ่านการตรวจสอบ'), findsOneWidget);
      await _flushPendingTimers(tester);
    });
  });

  // An offer that arrives after the farmer has started filling the form is
  // not thrown away: it waits in a banner instead of popping up over them.
  group('a late autofill offer', () {
    final form = _formWith([
      {'fieldName': 'notes', 'label': 'หมายเหตุ', 'inputType': 'VARCHAR', 'isMandatory': true, 'isActive': true, 'sortOrder': 1},
      {'fieldName': 'method', 'label': 'วิธีการ', 'inputType': 'VARCHAR', 'isMandatory': false, 'isActive': true, 'sortOrder': 2},
    ]);
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/form')) return jsonResponse({'form': form}, 200);
      if (request.url.path.endsWith('/autofill')) {
        return jsonResponse({
          'submitted_at': '2026-10-03T21:33:00Z',
          'answer': {'notes': 'จากครั้งก่อน', 'method': 'ฉีดพ่น'},
        }, 200);
      }
      return http.Response('', 404);
    });

    Future<void> startTypingBeforeTheOfferArrives(WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await tester.pumpWidget(wrapPage(
        const DynamicRegisterPage(handler: 'farm_activity', taskId: 't1', status: 'NOT_STARTED'),
        client: client,
      ));
      await tester.pumpAndSettle();
      // Typed while the offer is still on its way (the queue check alone
      // takes 500ms first).
      await tester.enterText(find.byType(TextFormField).first, 'พิมพ์เอง');
      await tester.pump();
      await _flushPendingTimers(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('shows a banner instead of popping up over the farmer', (tester) async {
      await startTypingBeforeTheOfferArrives(tester);

      expect(find.text('ใช้ข้อมูลเดิมจากครั้งล่าสุด?'), findsNothing);
      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsOneWidget);
      expect(find.text('บันทึกเมื่อ 3 ต.ค. 2569 — กดเพื่อดู'), findsOneWidget);
    });

    testWidgets('using it from the banner fills only the empty fields -- typing is kept', (tester) async {
      await startTypingBeforeTheOfferArrives(tester);

      await tester.tap(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ใช้ข้อมูลเดิม'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'พิมพ์เอง'), findsOneWidget, reason: 'never overwritten');
      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsNothing, reason: 'handled -> banner gone');

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'ฉีดพ่น'), findsOneWidget, reason: 'the empty one is filled');
    });

    testWidgets('closing the banner (x) drops the offer', (tester) async {
      await startTypingBeforeTheOfferArrives(tester);

      await tester.tap(find.byTooltip('ปิด'));
      await tester.pumpAndSettle();

      expect(find.text('มีข้อมูลเดิมจากครั้งล่าสุด'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'พิมพ์เอง'), findsOneWidget);
    });
  });
}

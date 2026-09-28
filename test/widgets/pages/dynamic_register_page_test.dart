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
}

// Widget tests for lib/widgets/components/dropdown_input.dart.
//
// This single component backs almost every "Choice" field in testcase.md
// (M-ROLE-01 role choice, M-PLOT-07 chemical info, M-FORM-02 activity,
// etc.) via FormHelper.buildDropdown, so its own correctness covers all
// of them: chip-list mode below 10 items, dropdown/search-dialog mode
// above 10 or when isDropdown is forced, and the built-in required
// validator.

import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapInForm(Widget child, GlobalKey<FormState> formKey) {
  return MaterialApp(home: Scaffold(body: Form(key: formKey, child: child)));
}

void main() {
  group('DropdownInput chip mode (<=10 items)', () {
    testWidgets('renders one chip per item and selects on tap', (tester) async {
      dynamic selected;
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        DropdownInput<String, String>(
          label: 'บทบาท',
          items: const ['farmer', 'processor'],
          value: null,
          onChanged: (v) => selected = v,
          itemLabelBuilder: (i) => i,
          itemValueBuilder: (i) => i,
        ),
        formKey,
      ));

      expect(find.text('farmer'), findsOneWidget);
      expect(find.text('processor'), findsOneWidget);

      await tester.tap(find.text('farmer'));
      await tester.pump();

      expect(selected, 'farmer');
    });

    testWidgets('required validator fails when nothing is selected', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        DropdownInput<String, String>(
          label: 'บทบาท',
          isRequired: true,
          items: const ['farmer'],
          value: null,
          onChanged: (_) {},
          itemLabelBuilder: (i) => i,
          itemValueBuilder: (i) => i,
        ),
        formKey,
      ));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('กรุณาเลือกข้อมูล'), findsOneWidget);
    });

    testWidgets('shows "ไม่มีข้อมูลให้เลือก" when the item list is empty', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        DropdownInput<String, String>(
          label: 'บทบาท',
          items: const [],
          value: null,
          onChanged: (_) {},
          itemLabelBuilder: (i) => i,
          itemValueBuilder: (i) => i,
        ),
        formKey,
      ));

      expect(find.text('ไม่มีข้อมูลให้เลือก'), findsOneWidget);
    });
  });

  group('DropdownInput search-dialog mode (isDropdown:true or >10 items)', () {
    testWidgets('tapping the field opens a search dialog and selecting an item calls onChanged', (tester) async {
      dynamic selected;
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        DropdownInput<String, String>(
          label: 'จังหวัด',
          isDropdown: true,
          items: const ['เชียงใหม่', 'ชุมพร'],
          value: null,
          onChanged: (v) => selected = v,
          itemLabelBuilder: (i) => i,
          itemValueBuilder: (i) => i,
        ),
        formKey,
      ));

      expect(find.text('กรุณาเลือกรายการ'), findsOneWidget);

      await tester.tap(find.text('กรุณาเลือกรายการ'));
      await tester.pumpAndSettle();

      expect(find.text('เชียงใหม่'), findsWidgets);

      await tester.tap(find.text('เชียงใหม่').last);
      await tester.pumpAndSettle();

      expect(selected, 'เชียงใหม่');
    });

    testWidgets('typing in the search box filters the list', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        DropdownInput<String, String>(
          label: 'จังหวัด',
          isDropdown: true,
          items: const ['เชียงใหม่', 'ชุมพร'],
          value: null,
          onChanged: (_) {},
          itemLabelBuilder: (i) => i,
          itemValueBuilder: (i) => i,
        ),
        formKey,
      ));

      await tester.tap(find.text('กรุณาเลือกรายการ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ชุม');
      await tester.pumpAndSettle();

      expect(find.text('ชุมพร'), findsOneWidget);
      expect(find.text('เชียงใหม่'), findsNothing);
    });
  });
}

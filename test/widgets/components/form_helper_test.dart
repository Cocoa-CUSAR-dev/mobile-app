// Widget tests for lib/widgets/components/form_helper.dart.
//
// FormHelper is a set of static factories wrapping the other input
// components with consistent bottom padding and a default required-field
// validator message. These tests check the wiring, not the wrapped
// components' own behavior (covered by their dedicated test files).

import 'package:cocoa_supply/widgets/components/checkbox_input.dart';
import 'package:cocoa_supply/widgets/components/date_input.dart';
import 'package:cocoa_supply/widgets/components/date_time_input.dart';
import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/widgets/components/number_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapInForm(Widget child, GlobalKey<FormState> formKey) {
  return MaterialApp(home: Scaffold(body: Form(key: formKey, child: child)));
}

void main() {
  group('FormHelper.buildInput', () {
    testWidgets('wraps a FormInput and applies the default required message', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormHelper.buildInput(label: 'ชื่อฟาร์ม', controller: TextEditingController(), isReq: true),
        formKey,
      ));

      expect(find.byType(FormInput), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('กรุณากรอกชื่อฟาร์ม'), findsOneWidget);
    });
  });

  group('FormHelper.buildNumber', () {
    testWidgets('wraps a NumberInput', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormHelper.buildNumber(label: 'จำนวน', controller: TextEditingController(text: '0')),
        ),
      ));

      expect(find.byType(NumberInput), findsOneWidget);
    });
  });

  group('FormHelper.buildDate', () {
    testWidgets('isTime:false wraps a DateInput', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FormHelper.buildDate(label: 'วันที่', controller: TextEditingController())),
      ));

      expect(find.byType(DateInput), findsOneWidget);
      expect(find.byType(DateTimeInput), findsNothing);
    });

    testWidgets('isTime:true wraps a DateTimeInput', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormHelper.buildDate(label: 'เวลา', controller: TextEditingController(), isTime: true),
        ),
      ));

      expect(find.byType(DateTimeInput), findsOneWidget);
    });
  });

  group('FormHelper.buildDropdown', () {
    testWidgets('wraps a DropdownInput and derives label/value from map entries', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormHelper.buildDropdown(
            label: 'จังหวัด',
            options: const [
              {'province_id': '50', 'province_name_th': 'เชียงใหม่'},
            ],
            currentValue: null,
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.byType(DropdownInput<Map<String, dynamic>, dynamic>), findsOneWidget);
      expect(find.text('เชียงใหม่'), findsOneWidget);
    });
  });

  group('FormHelper.buildCheckbox', () {
    testWidgets('wraps a CheckboxInput with the given initial value', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FormHelper.buildCheckbox(label: 'ใช้สารเคมี', value: true, onChanged: (_) {}),
        ),
      ));

      expect(find.byType(CheckboxInput), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });
  });
}

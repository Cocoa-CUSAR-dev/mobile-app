// Widget tests for lib/widgets/components/form_input.dart.

import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapInForm(Widget child, GlobalKey<FormState> formKey) {
  return MaterialApp(home: Scaffold(body: Form(key: formKey, child: child)));
}

void main() {
  group('FormInput', () {
    testWidgets('renders the label and passes typed text to the controller', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormInput(label: 'ชื่อฟาร์ม', controller: controller),
        formKey,
      ));

      expect(find.text('ชื่อฟาร์ม', findRichText: true), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'ไร่โกโก้พรีเมียม');
      expect(controller.text, 'ไร่โกโก้พรีเมียม');
    });

    testWidgets('runs the provided validator on Form.validate()', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormInput(
          label: 'ชื่อฟาร์ม',
          controller: controller,
          isRequired: true,
          validator: (v) => (v == null || v.isEmpty) ? 'กรุณาระบุชื่อฟาร์ม' : null,
        ),
        formKey,
      ));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('กรุณาระบุชื่อฟาร์ม'), findsOneWidget);
    });

    testWidgets('isPassword obscures the text field', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormInput(label: 'รหัสผ่าน', controller: controller, isPassword: true),
        formKey,
      ));

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
    });

    testWidgets('isTextArea renders a multi-line field with the requested line count', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormInput(label: 'หมายเหตุ', controller: controller, isTextArea: true, textAreaLines: 3),
        formKey,
      ));

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.minLines, 3);
      expect(field.maxLines, 3);
    });

    testWidgets('readOnly prevents editing', (tester) async {
      final controller = TextEditingController(text: 'preset');
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrapInForm(
        FormInput(label: 'ที่อยู่', controller: controller, readOnly: true),
        formKey,
      ));

      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.readOnly, isTrue);
    });
  });
}

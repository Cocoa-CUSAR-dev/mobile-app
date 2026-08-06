// Widget/unit tests for lib/widgets/components/upload_input.dart.
//
// KNOWN BUG (test below currently FAILS): UploadInput calls
// FilePicker.platform.pickFiles() with no type/allowedExtensions filter,
// so nothing rejects a non-image file — despite testcase.md rows like
// M-FARM-14/M-PLOT-18/M-STAT-15/M-HUB-15/M-FORM-09/25/39 all asserting
// "ระบบจะไม่ให้อับโหลดไฟล์ที่ผิด" (the system won't allow uploading the
// wrong file). A `pickFiles` override was added to UploadInput so the
// real OS file-picker platform channel doesn't need to be mocked here.

import 'package:cocoa_supply/widgets/components/upload_input.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FileUploadController', () {
    test('starts with no file', () {
      final controller = FileUploadController();
      expect(controller.hasFile, isFalse);
      expect(controller.value, isNull);
    });

    test('setting value notifies listeners and updates hasFile', () {
      final controller = FileUploadController();
      var notified = false;
      controller.addListener(() => notified = true);

      controller.value = PlatformFile(name: 'farm.jpg', size: 1024);

      expect(notified, isTrue);
      expect(controller.hasFile, isTrue);
      expect(controller.value!.name, 'farm.jpg');
    });

    test('clear() resets the value and notifies listeners', () {
      final controller = FileUploadController()..value = PlatformFile(name: 'farm.jpg', size: 1024);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.clear();

      expect(notified, isTrue);
      expect(controller.hasFile, isFalse);
    });
  });

  group('UploadInput', () {
    testWidgets('shows the placeholder text when no file is selected', (tester) async {
      final controller = FileUploadController();
      await tester.pumpWidget(wrap(UploadInput(label: 'รูปภาพประกอบฟาร์ม', controller: controller)));

      expect(find.text('เลือกไฟล์...'), findsOneWidget);
      expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
    });

    testWidgets('shows the file name and a clear button once a file is set', (tester) async {
      final controller = FileUploadController()..value = PlatformFile(name: 'farm.jpg', size: 1024);
      await tester.pumpWidget(wrap(UploadInput(label: 'รูปภาพประกอบฟาร์ม', controller: controller)));

      expect(find.text('farm.jpg'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('tapping the clear (X) button removes the selected file', (tester) async {
      final controller = FileUploadController()..value = PlatformFile(name: 'farm.jpg', size: 1024);
      await tester.pumpWidget(wrap(UploadInput(label: 'รูปภาพประกอบฟาร์ม', controller: controller)));

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();

      expect(controller.hasFile, isFalse);
      expect(find.text('เลือกไฟล์...'), findsOneWidget);
    });

    testWidgets(
      'M-FARM-14/M-PLOT-18/etc — picking a non-image file is rejected (KNOWN BUG: currently accepted)',
      (tester) async {
        final controller = FileUploadController();
        await tester.pumpWidget(wrap(UploadInput(
          label: 'รูปภาพประกอบฟาร์ม',
          controller: controller,
          pickFiles: () async => FilePickerResult([PlatformFile(name: 'document.pdf', size: 2048)]),
        )));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(controller.hasFile, isFalse, reason: 'a .pdf should be rejected, not accepted as an image');
        expect(find.text('เลือกไฟล์...'), findsOneWidget);
      },
    );
  });
}

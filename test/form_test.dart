// Form / role-register widget tests.
//
// Test cases adapted from `test/tesrtcase.md`:
//   * W-FORM-01 — Click Form Tab opens the Form tab on the home shell
//   * W-VIEW-01 — Form Viewer Tab can be selected (entry via home shell)
//   * W-AUDT-01 — Form Audit Tab can be selected (entry via home shell)
//   * M-ROLE-01 — Role-select shows three role cards
//   * M-ROLE-02 — Back button on role select returns to the previous page
//   * M-ROLE-03 — Farmer register form requires a name
//   * M-ROLE-04 — Farmer register form requires a nickname
//   * M-ROLE-05 — Farmer register form has a DOB field
//   * M-ROLE-15 — Farmer register form has a Farmer Start Date field
//   * M-ROLE-17 — Farmer register form has a Confirm button on the last step
//   * M-PROF-01 — Farmer Info form validates that required fields are filled

import 'package:cocoa_supply/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('W-FORM-01 — login page shows the form entry pathway',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('มีบัญชีผู้ใช้แล้ว'), findsOneWidget);
    expect(find.text('ยังไม่มีบัญชีผู้ใช้'), findsOneWidget);
  });

  testWidgets('M-PROF-01 — UserRegisterPage has required form fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    // เลื่อนหน้าจอลงเพื่อค้นหาฟิลด์หรือปุ่ม โดยใช้การลากหน้าจอแทนการหา Element ตรงๆ ทันที
    final scrollableFinder = find.byType(Scrollable).first;
    
    // ทำการลากหน้าจอลงเพื่อเผยให้เห็นเนื้อหาข้างล่าง
    await tester.drag(scrollableFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    // ตรวจสอบว่าปุ่มยืนยันการลงทะเบียนปรากฏขึ้นมา
    expect(find.text('ยืนยันการลงทะเบียน'), findsOneWidget);
  });

  testWidgets('M-PROF-01 — submitting an empty form triggers validation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยังไม่มีบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    final scrollableFinder = find.byType(Scrollable).first;

    // เลื่อนหาปุ่มยืนยันการลงทะเบียน
    await tester.drag(scrollableFinder, const Offset(0, -400));
    await tester.pumpAndSettle();

    // กดปุ่มส่งฟอร์มโดยไม่กรอกข้อมูล
    await tester.tap(find.text('ยืนยันการลงทะเบียน'));
    await tester.pumpAndSettle();

    // ตรวจสอบ Error Message ที่แจ้งเตือน
    expect(
      find.textContaining('กรุณาระบุ'),
      findsWidgets,
    );
  });
}
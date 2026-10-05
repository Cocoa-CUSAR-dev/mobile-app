// US2-5: ข้อเสนอ "ใช้ข้อมูลเดิมจากครั้งล่าสุด" สำหรับฟอร์มที่กำลังจะเปิด
//
// ข้อมูลมาจาก GET /tasks/:taskId/autofill ซึ่ง server คัดกรองมาแล้วด้วยฟังก์ชัน
// เดียวกับที่แชทบอทใช้ (validation.SanitizeAutofillAnswer ใน mobile-backend)
// ฝั่งแอปแค่จัดรูปให้แสดงผล -- ไม่ตัดสินเองว่าค่าไหนควรเสนอ

import 'package:cocoa_supply/bloc/dynamic/form_questions.dart';

class AutofillPreviewLine {
  final String label;
  final String value;
  const AutofillPreviewLine(this.label, this.value);
}

class AutofillOffer {
  final DateTime? submittedAt;
  // เฉพาะข้อที่มีอยู่ในฟอร์มปัจจุบัน -- ค่าที่ไม่มีคำถามรองรับไม่ถูกแสดงและไม่ถูกใช้
  final Map<String, dynamic> answer;
  // "label: value" เรียงตามลำดับคำถามในฟอร์ม
  final List<AutofillPreviewLine> preview;

  const AutofillOffer({
    required this.submittedAt,
    required this.answer,
    required this.preview,
  });

  /// Builds the offer the farmer sees from the server's response and the
  /// CURRENT form. Null when nothing on it is usable on this form.
  ///
  /// OPTION/BOOLEAN values are shown by their choice NAME from the current
  /// form, never the raw id -- the same resolution the chatbot's
  /// reuse.format_autofill_preview does, so a farmer who uses both sees the
  /// same text. BOOLEAN uses the chatbot's own "ใช่"/"ไม่".
  static AutofillOffer? fromResponse(
    Map<String, dynamic> response,
    Map<String, dynamic> form,
  ) {
    final raw = response['answer'];
    if (raw is! Map) return null;

    final answer = <String, dynamic>{};
    final preview = <AutofillPreviewLine>[];
    for (final question in flattenActiveQuestions(form)) {
      final fieldName = question['fieldName'] as String;
      final value = raw[fieldName];
      if (value == null) continue;
      answer[fieldName] = value;
      preview.add(AutofillPreviewLine(
        (question['label'] as String?) ?? fieldName,
        _displayValue(question, value),
      ));
    }
    if (answer.isEmpty) return null;

    final submittedAt = response['submitted_at'];
    return AutofillOffer(
      submittedAt: submittedAt is String ? DateTime.tryParse(submittedAt)?.toLocal() : null,
      answer: answer,
      preview: preview,
    );
  }

  static String _displayValue(Map<String, dynamic> question, dynamic value) {
    switch (question['inputType'] as String?) {
      case 'BOOLEAN':
        if (value == true || value == 'true') return 'ใช่';
        if (value == false || value == 'false') return 'ไม่';
        return value.toString();
      case 'OPTION':
        final choices = ((question['choices'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
        for (final choice in choices) {
          if (choice['id']?.toString() == value.toString()) {
            return (choice['name'] ?? value).toString();
          }
        }
        return value.toString();
      default:
        return value.toString();
    }
  }
}

const _thaiMonthsShort = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

/// "30 ก.ย. 2569" -- day, Thai short month, Buddhist Era year, the way
/// farmers read dates everywhere else in Thai.
String formatThaiShortDate(DateTime date) =>
    '${date.day} ${_thaiMonthsShort[date.month - 1]} ${date.year + 543}';

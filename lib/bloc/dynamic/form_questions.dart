// ไล่ sections[] -> questions[] ตาม sortOrder ให้เป็น list เดียว
// ข้าม section/question ที่ isActive == false (researcher ปิดการมองเห็นไว้)
//
// ใช้ร่วมกันระหว่างหน้าฟอร์ม (ลำดับคำถามที่แสดง) กับข้อเสนอ "ใช้ข้อมูลเดิม"
// (ลำดับบรรทัดในตัวอย่าง) -- ที่เดียว ลำดับเลยไม่มีทางไม่ตรงกัน
List<Map<String, dynamic>> flattenActiveQuestions(Map<String, dynamic> form) {
  final sections = ((form['sections'] as List<dynamic>?) ?? [])
      .cast<Map<String, dynamic>>()
      .where((s) => s['isActive'] != false)
      .toList()
    ..sort((a, b) => ((a['sortOrder'] ?? 0) as num).compareTo((b['sortOrder'] ?? 0) as num));

  final questions = <Map<String, dynamic>>[];
  for (final section in sections) {
    final sectionQuestions = ((section['questions'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((q) => q['isActive'] != false && q['fieldName'] != null)
        .toList()
      ..sort((a, b) => ((a['sortOrder'] ?? 0) as num).compareTo((b['sortOrder'] ?? 0) as num));
    questions.addAll(sectionQuestions);
  }
  return questions;
}

// US2-13: ตัวเลือกของคำถามที่ขึ้นกับคำถามอื่น (เช่น แปลง ที่ Kotlin ส่ง
// `dependsOn: "farm_id"` มา) เหลือเฉพาะตัวที่ `parentId` ตรงกับคำตอบของคำถาม
// แม่ -- แปลงของฟาร์มที่เพิ่งเลือก ถ้ายังไม่ได้ตอบคำถามแม่ก็แสดงทั้งหมด
// (ไม่ซ่อนอะไรจากการเดา) กติกาเดียวกับแชทบอท
List<Map<String, dynamic>> visibleChoices(
  Map<String, dynamic> question,
  Map<String, dynamic> answers,
) {
  final choices = ((question['choices'] as List<dynamic>?) ?? [])
      .cast<Map<String, dynamic>>();
  final parentField = question['dependsOn'] as String?;
  if (parentField == null) return choices;
  final parentValue = answers[parentField];
  if (parentValue == null || parentValue is List || parentValue.toString().isEmpty) {
    return choices;
  }
  return choices
      .where((c) => c['parentId']?.toString() == parentValue.toString())
      .toList();
}

// คำตอบที่ต้องล้างหลังคำถาม [changedField] เปลี่ยนค่า: แปลงที่เลือกไว้แต่ไม่อยู่
// ในฟาร์มใหม่ และต่อเป็นทอด -- ถ้าอำเภอถูกล้าง ตำบลที่เลือกไว้ก็ใช้ไม่ได้แล้ว
// (ไม่งั้นจะส่งไปให้ Go ปฏิเสธตอนส่งฟอร์ม)
List<String> staleDependentAnswers(
  List<Map<String, dynamic>> questions,
  String changedField,
  Map<String, dynamic> answers,
) {
  final stale = <String>[];
  final pending = [changedField];
  while (pending.isNotEmpty) {
    final parent = pending.removeAt(0);
    final parentCleared = stale.contains(parent);
    for (final question in questions) {
      final field = question['fieldName'] as String?;
      if (field == null || question['dependsOn'] != parent || stale.contains(field)) continue;
      final value = answers[field];
      if (value == null) continue;
      final stillFits = !parentCleared &&
          visibleChoices(question, answers)
              .any((c) => c['id']?.toString() == value.toString());
      if (!stillFits) {
        stale.add(field);
        pending.add(field);
      }
    }
  }
  return stale;
}

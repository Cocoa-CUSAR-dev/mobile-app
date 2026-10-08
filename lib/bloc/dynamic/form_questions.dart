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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateTimeInput extends StatefulWidget {
  final String label;
  final bool isRequired;
  final TextEditingController controller;

  const DateTimeInput({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
  });

  @override
  State<DateTimeInput> createState() => _DateTimeInputState();
}

class _DateTimeInputState extends State<DateTimeInput> {
  late int day, month, year, hour, minute;

  // คอนโทรลเลอร์ภายในสำหรับช่องกรอก
  late TextEditingController _dayCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _hourCtrl;
  late TextEditingController _minCtrl;

  @override
  void initState() {
    super.initState();
    _dayCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _hourCtrl = TextEditingController();
    _minCtrl = TextEditingController();
    _initValues();
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  void _initValues() {
    DateTime now = DateTime.now();
    if (widget.controller.text.isNotEmpty) {
      try {
        now = DateFormat('yyyy-MM-dd HH:mm:ss').parse(widget.controller.text);
      } catch (_) {}
    }
    day = now.day;
    month = now.month;
    year = now.year;
    hour = now.hour;
    minute = now.minute;

    _updateInternalText();
  }

  // อัปเดตข้อความในช่องกรอก (ใช้เมื่อเริ่มเครื่อง, กดปุ่ม +/-, หรือพิมพ์เสร็จแล้วกดที่อื่น)
  void _updateInternalText() {
    _dayCtrl.text = day.toString();
    _yearCtrl.text = (year + 543).toString();
    _hourCtrl.text = hour.toString().padLeft(2, '0');
    _minCtrl.text = minute.toString().padLeft(2, '0');
  }

  // ส่งค่ากลับไปยัง Controller หลักของ Widget
  void _saveToMainController() {
    final finalDate = DateTime(year, month, day, hour, minute);
    
    // อัปเดตตัวแปรเผื่อ DateTime มีการปัดเศษ (Roll-over)
    day = finalDate.day;
    month = finalDate.month;
    year = finalDate.year;
    hour = finalDate.hour;
    minute = finalDate.minute;

    widget.controller.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDate);
    setState(() {});
  }

  void _handleBtnClick(String type, int delta) {
    if (type == 'day') {
      var d = DateTime(year, month, day + delta, hour, minute);
      day = d.day; month = d.month; year = d.year;
    } else if (type == 'month') {
      var m = month + delta;
      if (m > 12) { month = 1; year++; }
      else if (m < 1) { month = 12; year--; }
      else { month = m; }
    } else if (type == 'year') {
      year += delta;
    } else if (type == 'hour') {
      var h = DateTime(year, month, day, hour + delta, minute);
      hour = h.hour; day = h.day; month = h.month; year = h.year;
    } else if (type == 'minute') {
      var min = DateTime(year, month, day, hour, minute + delta);
      minute = min.minute; hour = min.hour; day = min.day; month = min.month; year = min.year;
    }
    _saveToMainController();
    _updateInternalText();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 12),
        // แถวที่ 1: วัน เดือน ปี
        Row(
          children: [
            _buildPicker("วัน", _dayCtrl, (v) => day = int.tryParse(v) ?? day, 'day'),
            const SizedBox(width: 8),
            _buildStaticPicker("เดือน", _getMonthName(month), 'month', flex: 2),
            const SizedBox(width: 8),
            _buildPicker("ปี พ.ศ.", _yearCtrl, (v) => year = (int.tryParse(v) ?? (year + 543)) - 543, 'year'),
          ],
        ),
        const SizedBox(height: 12),
        // แถวที่ 2: เวลา
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildPicker("ชม.", _hourCtrl, (v) => hour = int.tryParse(v) ?? hour, 'hour'),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 24, 8, 0),
              child: Text(":", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            _buildPicker("นาที", _minCtrl, (v) => minute = int.tryParse(v) ?? minute, 'minute'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // สำหรับช่องที่พิมพ์ได้
  Widget _buildPicker(String label, TextEditingController ctrl, Function(String) onChanged, String type) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          _stepBtn(Icons.add, () => _handleBtnClick(type, 1), isTop: true),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TextField(
              controller: ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              onChanged: (v) {
                onChanged(v);
                _saveToMainController(); // บันทึกทันทีที่พิมพ์แต่ไม่ทับ text ใน ctrl
              },
              onTapOutside: (_) {
                _updateInternalText(); // จัด format สวยๆ (เช่น เติม 0) เมื่อเลิกพิมพ์
                FocusScope.of(context).unfocus();
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          _stepBtn(Icons.remove, () => _handleBtnClick(type, -1), isTop: false),
        ],
      ),
    );
  }

  // สำหรับช่องเดือน (คลิกเพิ่ม/ลดอย่างเดียว)
  Widget _buildStaticPicker(String label, String value, String type, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          _stepBtn(Icons.add, () => _handleBtnClick(type, 1), isTop: true),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _stepBtn(Icons.remove, () => _handleBtnClick(type, -1), isTop: false),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {required bool isTop}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: isTop ? const BorderRadius.vertical(top: Radius.circular(8)) : const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF794c46)),
      ),
    );
  }

  String _getMonthName(int m) {
    const months = ["", "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
    return (m > 0 && m <= 12) ? months[m] : "";
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        children: [if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      ),
    );
  }
}
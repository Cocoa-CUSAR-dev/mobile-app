import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DateInput extends StatefulWidget {
  final String label;
  final bool isRequired;
  final TextEditingController controller;

  const DateInput({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
  });

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  late int day, month, year;
  
  // เพิ่ม Controller สำหรับช่องกรอก
  late TextEditingController _dayInputController;
  late TextEditingController _yearInputController;

  @override
  void initState() {
    super.initState();
    _dayInputController = TextEditingController();
    _yearInputController = TextEditingController();
    _parseInitialValue();
  }

  @override
  void dispose() {
    _dayInputController.dispose();
    _yearInputController.dispose();
    super.dispose();
  }

  void _parseInitialValue() {
    DateTime initialDate = DateTime.now();
    if (widget.controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(widget.controller.text);
      } catch (e) {
        initialDate = DateTime.now();
      }
    }
    day = initialDate.day;
    month = initialDate.month;
    year = initialDate.year;
    
    // ตั้งค่าเริ่มต้นให้ช่องกรอก
    _dayInputController.text = day.toString();
    _yearInputController.text = (year + 543).toString();
  }

  void _updateController() {
    // ป้องกันกรณีใส่วันที่ไม่มีจริง เช่น 31 ก.พ. DateTime จะปัดเป็น 3 มี.ค. อัตโนมัติ
    final date = DateTime(year, month, day);
    widget.controller.text = DateFormat('yyyy-MM-dd').format(date);
    
    // อัปเดตตัวเลขในช่องกรอกให้ตรงกับ State (กรณีเกิดจากการกดปุ่ม +/-)
    if (_dayInputController.text != date.day.toString()) {
      _dayInputController.text = date.day.toString();
    }
    if (_yearInputController.text != (date.year + 543).toString()) {
      _yearInputController.text = (date.year + 543).toString();
    }
    
    // อัปเดตตัวแปรภายในเผื่อ DateTime มีการดีดวัน (เช่น พิมพ์วันที่ 32)
    day = date.day;
    month = date.month;
    year = date.year;
    
    setState(() {});
  }

  void _changeValue(String type, int delta) {
    if (type == 'day') {
      var date = DateTime(year, month, day + delta);
      day = date.day; month = date.month; year = date.year;
    } else if (type == 'month') {
      var newMonth = month + delta;
      if (newMonth > 12) { month = 1; year++; }
      else if (newMonth < 1) { month = 12; year--; }
      else { month = newMonth; }
    } else if (type == 'year') {
      year += delta;
    }
    _updateController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(widget.label, widget.isRequired),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildUnitPicker(
              "วัน", 
              'day', 
              isEditable: true, 
              textController: _dayInputController,
              onChanged: (val) {
                day = int.tryParse(val) ?? day;
                _updateController();
              }
            ),
            const SizedBox(width: 8),
            _buildUnitPicker("เดือน", 'month', displayValue: _getMonthName(month), flex: 2),
            const SizedBox(width: 8),
            _buildUnitPicker(
              "ปี พ.ศ.", 
              'year', 
              isEditable: true, 
              textController: _yearInputController,
              onChanged: (val) {
                int inputYear = int.tryParse(val) ?? (year + 543);
                year = inputYear - 543; // แปลง พ.ศ. เป็น ค.ศ.
                _updateController();
              }
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnitPicker(
    String label, 
    String type, {
    int flex = 1, 
    String? displayValue, 
    bool isEditable = false,
    TextEditingController? textController,
    Function(String)? onChanged,
  }) {
    return Expanded(
      flex: flex,
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          _stepBtn(Icons.add, () => _changeValue(type, 1), isTop: true),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 0), // ปรับ padding เพื่อครอบ TextField
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
            ),
            child: isEditable 
              ? TextField(
                  controller: textController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    displayValue ?? "", 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
          ),
          _stepBtn(Icons.remove, () => _changeValue(type, -1), isTop: false),
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
          borderRadius: isTop 
            ? const BorderRadius.vertical(top: Radius.circular(8)) 
            : const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF794c46)),
      ),
    );
  }

  String _getMonthName(int m) {
    const months = ["", "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค. "];
    return (m > 0 && m <= 12) ? months[m] : "";
  }

  Widget _buildLabel(String label, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NumberInput extends StatefulWidget {
  final String label;
  final bool isRequired;
  final TextEditingController controller;
  final bool isInt; // true สำหรับจำนวนเต็ม, false สำหรับทศนิยม
  final int interval;

  const NumberInput({
    super.key,
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.isInt = true,
    this.interval = 1,
  });

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  
  @override
  void initState() {
    super.initState();
    _formatValue();
  }

  // ฟังก์ชันจัดรูปแบบตามประเภทข้อมูล
  void _formatValue() {
    double current = double.tryParse(widget.controller.text) ?? 0.0;
    if (widget.isInt) {
      widget.controller.text = current.toInt().toString();
    } else {
      widget.controller.text = current.toStringAsFixed(2); // แสดง N2 เฉพาะทศนิยม
    }
  }

  void _updateValue(double step) {
    double current = double.tryParse(widget.controller.text) ?? 0.0;
    double newValue = (current + step >= 0) ? current + step : 0.0;

    setState(() {
      if (widget.isInt) {
        widget.controller.text = newValue.toInt().toString();
      } else {
        widget.controller.text = newValue.toStringAsFixed(2); // แสดง N2 เมื่อเป็นทศนิยม
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(widget.label, widget.isRequired),
        const SizedBox(height: 12),
        Focus(
          onFocusChange: (hasFocus) {
            // เมื่อออกจากช่องกรอก ให้จัดรูปแบบใหม่ตามเงื่อนไข isInt
            if (!hasFocus) {
              setState(() {
                _formatValue();
              });
            }
          },
          child: TextField(
            controller: widget.controller,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF794c46)
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: !widget.isInt),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _expandedStepBtn("-${widget.interval}", () => _updateValue(-widget.interval.toDouble())),
            const SizedBox(width: 8),
            // แสดงปุ่มละเอียดเฉพาะกรณีที่เป็นทศนิยม
            if (!widget.isInt) ...[
              _expandedStepBtn("-0.10", () => _updateValue(-0.1)),
              const SizedBox(width: 8),
              _expandedStepBtn("+0.10", () => _updateValue(0.1)),
              const SizedBox(width: 8),
            ],
            _expandedStepBtn("+${widget.interval}", () => _updateValue(widget.interval.toDouble())),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _expandedStepBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class CheckboxInput extends StatefulWidget {
  final String label;
  final bool? initialValue; // เปลี่ยนเป็น nullable เพื่อรองรับสถานะยังไม่ได้เลือก
  final ValueChanged<bool>? onChanged;
  final bool isRequired;

  const CheckboxInput({
    super.key,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.onChanged,
  });

  @override
  State<CheckboxInput> createState() => _CheckboxInputState();
}

class _CheckboxInputState extends State<CheckboxInput> {
  bool? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 12),
        Row(
          children: [
            // Column 1: ใช่
            Expanded(
              child: _buildOption(
                label: 'ใช่',
                isSelected: _selectedValue == true,
                onTap: () => _handleChanged(true),
              ),
            ),
            const SizedBox(width: 12), // ช่องว่างระหว่างคอลัมน์
            // Column 2: ไม่ใช่
            Expanded(
              child: _buildOption(
                label: 'ไม่ใช่',
                isSelected: _selectedValue == false,
                onTap: () => _handleChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = const Color(0x88794c46);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radio Icon สไตล์ MUI
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryColor : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'NotoSansThaiLooped',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChanged(bool newValue) {
    setState(() => _selectedValue = newValue);
    if (widget.onChanged != null) {
      widget.onChanged!(newValue);
    }
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'NotoSansThaiLooped',
        ),
        children: [
          if (widget.isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
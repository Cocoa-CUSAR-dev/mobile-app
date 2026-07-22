import 'package:flutter/material.dart';

/// Component สำหรับ Form Input ที่นำมาใช้ซ้ำได้
class FormInput extends StatelessWidget {
  final String label;
  final String? hintText;
  final bool isPassword;
  final bool isRequired;
  final bool isTextArea; // เพิ่ม textarea mode
  final int textAreaLines; // จำนวนบรรทัด textarea
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;

  const FormInput({
    super.key,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.isRequired = false,
    this.isTextArea = false,
    this.textAreaLines = 4,
    this.validator,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Label
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'NotoSansThaiLooped',
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                ],
              ),
            ),
          ),

          /// Input Field
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            obscureText: isPassword,
            keyboardType: isTextArea
                ? TextInputType.multiline
                : keyboardType,
            validator: validator,
            onTap: onTap,
            readOnly: readOnly,

            /// textarea support
            minLines: isTextArea ? textAreaLines : 1,
            maxLines: isTextArea ? textAreaLines : 1,

            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'NotoSansThaiLooped',
            ),
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              fillColor:
                  readOnly ? Colors.grey.shade50 : Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide:
                    const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide:
                    BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                    color: Color(0xFF794c46), width: 2),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}
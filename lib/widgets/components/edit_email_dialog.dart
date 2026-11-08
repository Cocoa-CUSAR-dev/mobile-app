import 'package:cocoa_supply/services/email_validation.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter/material.dart';

/// Add, change or remove the account's email. Pops true once saved; leaving
/// the field blank removes the email.
class EditEmailDialog extends StatefulWidget {
  final String? email;
  final Future<void> Function(String email) onSave;

  const EditEmailDialog({super.key, this.email, required this.onSave});

  @override
  State<EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<EditEmailDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.email);
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _controller.text.trim();
    final invalid = emailError(email);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(email);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // The hub's own Thai message (e.g. someone else uses this email).
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e is ServerRejection ? e.message : 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('อีเมล'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'เช่น name@example.com',
          helperText: 'ใช้เข้าสู่ระบบได้ เว้นว่างเพื่อลบอีเมล',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

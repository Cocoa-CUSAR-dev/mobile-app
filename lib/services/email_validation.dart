/// What's wrong with an optional email, or null if it's fine. Blank is fine:
/// it means no email. The backend has the last word on the format.
String? emailError(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return null;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'รูปแบบอีเมลไม่ถูกต้อง';
  }
  return null;
}

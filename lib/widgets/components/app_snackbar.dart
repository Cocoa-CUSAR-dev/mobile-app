import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';

/// What kind of feedback this snackbar is giving -- picks the icon/accent
/// color. Purely presentational; never changes the message text itself.
enum AppSnackBarType { success, error, info }

/// Shared success/error/info feedback, in place of the raw, unstyled
/// SnackBar(content: Text(...)) calls scattered across the register/login
/// flows (plain banner, sometimes not even themed red for errors).
/// Floating, rounded, with an icon -- reads as a deliberate part of the UI
/// instead of a stock Material default.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    final IconData icon;
    final Color accent;
    switch (type) {
      case AppSnackBarType.success:
        icon = Icons.check_circle_outline;
        accent = const Color(0xFF2E7D32);
        break;
      case AppSnackBarType.error:
        icon = Icons.error_outline;
        accent = const Color(0xFFC62828);
        break;
      case AppSnackBarType.info:
        icon = Icons.info_outline;
        accent = AppColors.primary;
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 3,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withValues(alpha: 0.3)),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextTheme.scale.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

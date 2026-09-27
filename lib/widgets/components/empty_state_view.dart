import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';

/// Shared "no data" placeholder, used wherever a list/detail view has
/// nothing to show. Was previously copy-pasted per page as a plain grey
/// icon + text (farm/hub/processing-station pages), a bare Text with no
/// icon at all (the profile sheet, and the home page's task list, which
/// rendered nothing whatsoever when empty) -- centralized here so every
/// empty state looks intentional and matches the app's theme colors.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateView({
    super.key,
    this.icon = Icons.inventory_2_outlined,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryFaint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextTheme.scale.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

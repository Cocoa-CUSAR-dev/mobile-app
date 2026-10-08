import 'package:flutter/material.dart';

import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

/// US2-5: "ใช้ข้อมูลเดิมจากครั้งล่าสุด?" -- shown once over the first page of a
/// new form when DynamicBloc has a last answer to offer.
///
/// Purely presentational: what to offer, in what order and with which
/// wording, is decided in DynamicBloc/AutofillOffer. The button wording is
/// the chatbot's own ("ใช้ข้อมูลเดิม" / "เริ่มใหม่") so a farmer who uses both
/// channels sees the same choice in both places.
class AutofillOfferSheet extends StatelessWidget {
  final AutofillOffer offer;

  const AutofillOfferSheet({super.key, required this.offer});

  /// Shows the sheet and resolves to true only for "ใช้ข้อมูลเดิม".
  /// Dismissing it any other way (back, tapping outside, dragging it down)
  /// counts as "เริ่มใหม่" -- doing nothing must never fill in a form.
  static Future<bool> show(BuildContext context, AutofillOffer offer) async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AutofillOfferSheet(offer: offer),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submittedAt = offer.submittedAt;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ใช้ข้อมูลเดิมจากครั้งล่าสุด?',
              style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
            ),
            if (submittedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'บันทึกเมื่อ ${formatThaiShortDate(submittedAt)}',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
            const Divider(height: 32),
            // Long forms must not push the buttons off screen.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in offer.preview)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${line.label}: ${line.value}', style: textTheme.bodyLarge),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text('เริ่มใหม่', style: textTheme.bodyLarge?.copyWith(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('ใช้ข้อมูลเดิม', style: textTheme.bodyLarge?.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

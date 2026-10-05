import 'package:flutter/material.dart';

import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

/// US2-5: a standing reminder that last time's answers can still be used.
///
/// The offer arrives a moment after the form opens (it waits on the network,
/// on purpose -- the form never does). If the farmer has already started
/// filling the form by then, a popup jumping in front of them would be in the
/// way, but silently throwing the offer away would make it easy to miss
/// entirely. So it stays here, at the top of every page of the form, until
/// they open it or close it.
class AutofillOfferBanner extends StatelessWidget {
  final AutofillOffer offer;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const AutofillOfferBanner({
    super.key,
    required this.offer,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submittedAt = offer.submittedAt;

    return Material(
      color: AppColors.primaryFaint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('มีข้อมูลเดิมจากครั้งล่าสุด', style: textTheme.bodyLarge),
                    if (submittedAt != null)
                      Text(
                        'บันทึกเมื่อ ${formatThaiShortDate(submittedAt)} — กดเพื่อดู',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ปิด',
                icon: const Icon(Icons.close_rounded),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

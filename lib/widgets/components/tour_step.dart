import 'package:cocoa_supply/services/tour_controller.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// One highlighted widget in the guided tour (docs-and-plan#311): a short
/// Thai title and explanation in large text, with "ถัดไป", "ย้อนกลับ" and
/// "ข้าม". "ข้าม" ends the whole tour (see [TourController.skip]).
///
/// Give each step a GlobalKey and pass the page's keys, in order, to
/// [TourController.show].
///
/// With [onTap], the step has no "ถัดไป": the person taps the highlighted
/// widget itself, which does what that widget does (open a tab or a page)
/// and moves the tour on. Use it for steps that lead somewhere, so farmers
/// press the real button once; keep "ถัดไป" for steps that only explain.
class TourStep extends StatelessWidget {
  const TourStep({
    required GlobalKey stepKey,
    required this.title,
    required this.description,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    super.key,
  }) : _stepKey = stepKey;

  final GlobalKey _stepKey;
  final String title;
  final String description;
  final Widget child;

  /// The page's first step has no "ย้อนกลับ".
  final bool isFirst;

  /// The page's last step says "เข้าใจแล้ว" instead of "ถัดไป".
  final bool isLast;

  final ShapeBorder shape;

  /// What tapping the highlighted widget does; see the class comment.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Registers the tour's showcase scope before Showcase looks it up.
    TourController.instance;
    return Showcase(
      key: _stepKey,
      scope: TourController.scope,
      title: title,
      description: description,
      titleTextStyle: AppTextTheme.scale.titleLarge?.copyWith(color: AppColors.primary),
      descTextStyle: AppTextTheme.scale.bodyLarge,
      titleAlignment: Alignment.centerLeft,
      descriptionAlignment: Alignment.centerLeft,
      tooltipPadding: const EdgeInsets.all(16),
      tooltipBorderRadius: BorderRadius.circular(16),
      targetShapeBorder: shape,
      targetPadding: const EdgeInsets.all(6),
      // Taps outside the tooltip don't end the tour by accident.
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      // disposeOnTap: true would end the whole tour (it dismisses, like
      // ข้าม), so move on first and then do what the widget does.
      onTargetClick: onTap == null
          ? null
          : () {
              TourController.instance.next();
              onTap!();
            },
      disposeOnTap: onTap == null ? null : false,
      tooltipActionConfig: const TooltipActionConfig(
        alignment: MainAxisAlignment.end,
        actionGap: 8,
        gapBetweenContentAndAction: 16,
      ),
      tooltipActions: [
        _action(TooltipDefaultActionType.skip, 'ข้าม', filled: false),
        if (!isFirst) _action(TooltipDefaultActionType.previous, 'ย้อนกลับ', filled: false),
        if (onTap == null)
          _action(TooltipDefaultActionType.next, isLast ? 'เข้าใจแล้ว' : 'ถัดไป', filled: true),
      ],
      child: child,
    );
  }

  TooltipActionButton _action(TooltipDefaultActionType type, String label, {required bool filled}) {
    return TooltipActionButton(
      type: type,
      name: label,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: filled ? AppColors.primary : Colors.white,
      border: filled ? null : Border.all(color: AppColors.primary),
      textStyle: AppTextTheme.scale.titleSmall?.copyWith(
        color: filled ? Colors.white : AppColors.primary,
      ),
    );
  }
}

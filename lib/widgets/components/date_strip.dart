import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';

/// Horizontally scrollable strip of day chips, replacing the old
/// "< date >" pair of buttons that only moved one day at a time (and that,
/// at narrower widths, overflowed -- the date text + two 48dp IconButtons
/// didn't fit in one Row). Tapping any visible day jumps straight to it;
/// scrolling (drag/swipe) reveals more days either direction. Jumping
/// further than the visible window is what the calendar-icon button next
/// to the date header is for, not an arrow bolted onto this strip.
///
/// `anchorDate` is owned by the caller, not computed internally, because
/// HomeTabContent swaps in a loading spinner in place of this whole widget
/// between date changes (see home_page.dart's HomeLoading branch), which
/// unmounts and remounts DateStrip on every single date change. An anchor
/// computed fresh in initState from `selectedDate` would re-center the
/// visible window on whatever day was just tapped every time -- the
/// caller keeps one stable DateTime across that remount cycle and only
/// moves it when `selectedDate` would otherwise fall outside the strip.
class DateStrip extends StatefulWidget {
  // Generous on purpose: this is the whole scrollable range around the
  // anchor before it just runs out ("cuts off" mid-scroll, reported live
  // after nudging/dragging repeatedly) -- ListView.builder only builds
  // the chips actually on screen, so a wide window here costs nothing at
  // rest. Jumping further than even this is what the calendar-icon button
  // is for.
  static const int daysBefore = 60;
  static const int daysAfter = 60;

  final DateTime anchorDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateStrip({
    super.key,
    required this.anchorDate,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _thaiWeekdayAbbr = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
  final ScrollController _scrollController = ScrollController();

  static const double _itemWidth = 56;
  static const double _itemGap = 10;
  static const double _edgeReserve = 40;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedWhenReady());
  }

  // The ListView's ScrollPosition can report a stale/zero viewportDimension
  // on the very first post-frame callback in some cases (e.g. right after
  // this widget mounts inside a ConstrainedBox) -- retry a couple of
  // frames rather than centering against a bogus width once.
  void _scrollToSelectedWhenReady({int attemptsLeft = 3}) {
    if (!mounted) return;
    if (!_scrollController.hasClients || _scrollController.position.viewportDimension <= 0) {
      if (attemptsLeft > 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToSelectedWhenReady(attemptsLeft: attemptsLeft - 1),
        );
      }
      return;
    }
    _scrollToSelected(animate: false);
  }

  void _nudge(int days) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + days * (_itemWidth + _itemGap))
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate) ||
        !_isSameDay(oldWidget.anchorDate, widget.anchorDate)) {
      _scrollToSelected(
        animate: !_isSameDay(oldWidget.anchorDate, widget.anchorDate)
            ? false
            : true,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _scrollToSelected({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final index =
        widget.selectedDate.difference(widget.anchorDate).inDays +
        DateStrip.daysBefore;
    final itemStart = index * (_itemWidth + _itemGap);
    // Center the selected chip in the viewport rather than nudging it in
    // from the left edge -- on a wide (desktop) viewport a fixed nudge
    // left it stuck near the left edge instead of showing days on both
    // sides of it.
    final viewportWidth = _scrollController.position.viewportDimension;
    final target = itemStart - (viewportWidth / 2) + (_itemWidth / 2);
    final clamped = target.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    if (animate) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  Widget _edgeFade({required bool alignLeft, required VoidCallback onTap}) {
    return Positioned(
      left: alignLeft ? 0 : null,
      right: alignLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          width: _edgeReserve,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Align(
            alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1.5,
              shadowColor: Colors.black26,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    alignLeft ? Icons.chevron_left : Icons.chevron_right,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // This app's real target is a phone screen -- on a wide desktop
  // viewport (only reachable through the web test build), letting the
  // strip fill the whole width crams ~19 chips edge-to-edge into one
  // glance, which reads as visual noise rather than a scrollable strip.
  // Capping the width keeps the same phone-sized chunk visible
  // everywhere; it's a no-op on an actual phone-width viewport.
  static const double _maxStripWidth = 420;

  @override
  Widget build(BuildContext context) {
    final totalDays = DateStrip.daysBefore + DateStrip.daysAfter + 1;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxStripWidth),
      child: SizedBox(
        height: 68,
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _edgeReserve - 4),
              itemCount: totalDays,
              itemBuilder: (context, index) {
                final date = widget.anchorDate.add(
                  Duration(days: index - DateStrip.daysBefore),
                );
                final isSelected = _isSameDay(date, widget.selectedDate);
                return Padding(
                  padding: const EdgeInsets.only(right: _itemGap),
                  child: GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _itemWidth,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _thaiWeekdayAbbr[date.weekday - 1],
                            style: AppTextTheme.scale.labelSmall?.copyWith(
                              color: isSelected
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: AppTextTheme.scale.titleMedium?.copyWith(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            _edgeFade(alignLeft: true, onTap: () => _nudge(-3)),
            _edgeFade(alignLeft: false, onTap: () => _nudge(3)),
          ],
        ),
      ),
    );
  }
}

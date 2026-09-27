import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';

/// Horizontally scrollable strip of day chips, replacing the old
/// "< date >" pair of buttons that only moved one day at a time (and that,
/// at narrower widths, overflowed -- the date text + two 48dp IconButtons
/// didn't fit in one Row). Tapping any visible day jumps straight to it;
/// scrolling reveals more days either direction without repeated taps.
class DateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateStrip({super.key, required this.selectedDate, required this.onDateSelected});

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _thaiWeekdayAbbr = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  // Anchored to today, not to widget.selectedDate: HomeTabContent swaps in
  // a loading spinner in place of this whole widget between date changes
  // (see home_page.dart's HomeLoading branch), which unmounts and remounts
  // DateStrip -- an anchor taken from the constructor argument would reset
  // to whatever date was just tapped on every remount, making the visible
  // window jump to a new position on every single tap instead of staying
  // put. "Today" stays constant across those remounts within the same day.
  late final DateTime _anchor = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }();
  final ScrollController _scrollController = ScrollController();

  static const int _daysBefore = 7;
  static const int _daysAfter = 21;
  static const double _itemWidth = 56;
  static const double _itemGap = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void didUpdateWidget(DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      _scrollToSelected(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _scrollToSelected({required bool animate}) {
    final index = widget.selectedDate.difference(_anchor).inDays + _daysBefore;
    final target = (index * (_itemWidth + _itemGap)) - 24;
    if (!_scrollController.hasClients) return;
    final clamped = target.clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(clamped, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _daysBefore + _daysAfter + 1;
    return SizedBox(
      height: 68,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final date = _anchor.add(Duration(days: index - _daysBefore));
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
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _thaiWeekdayAbbr[date.weekday - 1],
                      style: AppTextTheme.scale.labelSmall?.copyWith(
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
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
    );
  }
}

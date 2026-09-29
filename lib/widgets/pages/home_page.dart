import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:cocoa_supply/services/util_service.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/components/empty_state_view.dart';
import 'package:cocoa_supply/widgets/components/app_snackbar.dart';
import 'package:cocoa_supply/widgets/components/date_strip.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/root_scaffold.dart';
import 'package:cocoa_supply/widgets/pages/farm_page.dart';
import 'package:cocoa_supply/widgets/pages/hub_page.dart';
import 'package:cocoa_supply/widgets/pages/processing_station_page.dart';

// --- HomePage ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Widget> _tabPages = [
    const HomeTabContent(), // ตอนนี้เป็น StatefulWidget แล้ว
    const FarmPage(),
    const ProcessingStationPage(),
    const HubPage(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(
      HomeDataRequested(selectedDate: DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeLoadFailure) {
          AppSnackBar.show(context, 'เกิดข้อผิดพลาด: ${state.error}', type: AppSnackBarType.error);
        }
      },
      builder: (context, state) {
        int currentIndex = 0;
        if (state is HomeInitial) currentIndex = state.currentTabIndex;
        if (state is HomeLoading) currentIndex = state.currentTabIndex;
        if (state is HomeLoaded) currentIndex = state.currentTabIndex;
        final titles = ['หน้าหลัก', 'ฟาร์ม', 'สถานีแปรรูป', 'หน่วยรวบรวม'];

        return RootScaffold(
          title: titles[currentIndex],
          currentIndex: currentIndex,
          onItemSelected: (index) {
            context.read<HomeBloc>().add(HomeTabChanged(newIndex: index));
          },
          children: _tabPages,
        );
      },
    );
  }
}

// --- HomeTabContent (เปลี่ยนเป็น StatefulWidget) ---
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  // Owned here (not inside DateStrip) because HomeTabContent swaps this
  // whole subtree for a loading spinner between date changes, unmounting
  // and remounting DateStrip -- this State object is what actually
  // survives that cycle. Starts at today; _ensureAnchorCovers moves it
  // only when the calendar picker jumps somewhere the strip doesn't reach.
  late DateTime _stripAnchor = _normalizeDate(DateTime.now());

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  void _ensureAnchorCovers(DateTime date) {
    final diff = date.difference(_stripAnchor).inDays;
    if (diff < -DateStrip.daysBefore || diff > DateStrip.daysAfter) {
      _stripAnchor = _normalizeDate(date);
    }
  }

  // จัดการการเปลี่ยนหน้าและรับผลลัพธ์กลับมา
  Future<void> _navigateToDetail(BuildContext context, TaskItem task) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoute.dynamicRegister,
      arguments: {
        'handler': task.handler,
        'taskId': task.taskId,
        'status': task.status,
      },
    );
    if(mounted && result == true){
      context.read<HomeBloc>().add(
        HomeDataRequested(selectedDate: DateTime.now()),
      );
    }
  }

  // เปิดปฏิทินแบบเต็ม (เลือกเดือน/ปี แล้วแตะวันได้ตรงๆ) -- ทำเป็นทางเลือกคู่กับ
  // DateStrip ด้านบน สำหรับตอนต้องการกระโดดข้ามหลายเดือนทีเดียว
  Future<void> _openCalendarPicker(BuildContext context, DateTime selectedDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 5),
      lastDate: DateTime(selectedDate.year + 5),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<HomeBloc>().add(HomeDataRequested(selectedDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: ThreeDotsLoading());
        }
        if (state is HomeLoaded) {
          _ensureAnchorCovers(state.selectedDate);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวเรื่องและตัวเลือกวันที่
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'วันที่ ${UtilService.formatThaiDate(state.selectedDate)}',
                        style: AppTextTheme.scale.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                      tooltip: 'เปิดปฏิทิน',
                      onPressed: () => _openCalendarPicker(context, state.selectedDate),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DateStrip(
                  anchorDate: _stripAnchor,
                  selectedDate: state.selectedDate,
                  onDateSelected: (date) => context.read<HomeBloc>().add(
                    HomeDataRequested(selectedDate: date),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "สิ่งที่ต้องทำ",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 12),

                // รายการ Task Cards
                if (state.dailyTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyStateView(
                      icon: Icons.check_circle_outline,
                      message: "ไม่มีสิ่งที่ต้องทำวันนี้",
                    ),
                  )
                else
                  ...state.dailyTasks.map(
                    (task) => _TaskCard(
                      title: task.title,
                      detail: task.description,
                      status: task.status,
                      statusText: task.statusText,
                      statusColor: task.statusColor,
                      dueDate: task.closeAt,
                      onTap: () => _navigateToDetail(context, task),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// --- คอมโพเนนต์ Card สำหรับ Task (คงเดิมไว้เป็น Stateless เพราะทำหน้าที่แสดงผลอย่างเดียว) ---
class _TaskCard extends StatelessWidget {
  final String title;
  final String detail;
  final String status;
  final String statusText;
  final Color statusColor;
  final DateTime? dueDate;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.detail,
    required this.status,
    required this.statusText,
    required this.statusColor,
    required this.dueDate,
    required this.onTap,
  });

  IconData get _statusIcon {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.sync;
      case 'OVERDUE':
        return Icons.error;
      case 'NOT_STARTED':
      default:
        return Icons.schedule;
    }
  }

  static const _thaiMonthsAbbr = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/bg2.png',
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(_statusIcon, color: statusColor, size: 22),
                      ],
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'ครบกำหนด ${dueDate!.day} ${_thaiMonthsAbbr[dueDate!.month - 1]}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
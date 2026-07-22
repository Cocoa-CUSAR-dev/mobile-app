import 'package:cocoa_supply/bloc/home/home_bloc.dart';
import 'package:cocoa_supply/bloc/home/home_event.dart';
import 'package:cocoa_supply/bloc/home/home_state.dart';
import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:cocoa_supply/services/util_service.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.error}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: ThreeDotsLoading());
        }
        if (state is HomeLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวเรื่องและตัวเลือกวันที่
                Row(
                  children: [
                    Text(
                      'วันที่ ${UtilService.formatThaiDate(state.selectedDate)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 30),
                      onPressed: () => context.read<HomeBloc>().add(
                        HomeDataRequested(
                          selectedDate: state.selectedDate.subtract(
                            const Duration(days: 1),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 30),
                      onPressed: () => context.read<HomeBloc>().add(
                        HomeDataRequested(
                          selectedDate: state.selectedDate.add(
                            const Duration(days: 1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "สิ่งที่ต้องทำ",
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                const SizedBox(height: 12),

                // รายการ Task Cards
                ...state.dailyTasks.map(
                  (task) => _TaskCard(
                    title: task.title,
                    detail: task.description,
                    statusText: task.statusText,
                    statusColor: task.statusColor,
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
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.detail,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 18,
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
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
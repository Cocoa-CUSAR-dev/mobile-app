import 'package:cocoa_supply/bloc/hub/hub_bloc.dart';
import 'package:cocoa_supply/bloc/hub/hub_event.dart';
import 'package:cocoa_supply/bloc/hub/hub_state.dart';
import 'package:cocoa_supply/models/harvest_model.dart';
import 'package:cocoa_supply/services/util_service.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเมื่อเริ่มต้น Page
    _onRefresh();
  }

  /// ฟังก์ชันสำหรับดึงข้อมูลใหม่
  Future<void> _onRefresh() async {
    context.read<HubBloc>().add(LoadHubs());
  }

  /// นำทางไปยังหน้าลงทะเบียน Hub ใหม่
  void _navigateToRegister(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoute.hubRegister);
    if (mounted) {
      _onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: BlocBuilder<HubBloc, HubState>(
        builder: (context, state) {
          if (state is HubLoading || state is HubInitial) {
            return const Center(child: ThreeDotsLoading());
          }

          if (state is HubError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${state.message}'));
          }

          if (state is HubsLoaded) {
            final hubs = state.hubs;

            if (hubs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ไม่พบข้อมูลหน่วยรวบรวม',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              itemCount: hubs.length,
              itemBuilder: (context, index) {
                final hub = hubs[index];
                final harvests = hub.harvests ?? [];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            hub.hubName ?? "หน่วยรวบรวม",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: Image.asset(
                            'assets/images/hub.jpg',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// TRANSACTIONS (ธุรกรรมของ Hub)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DataRecordContainer<Harvest>(
                            title: 'ธุรกรรมการรับซื้อ',
                            subtitle: 'ข้อมูลการรับซื้อล่าสุด',
                            items: harvests,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                            cardColor: const Color(0xFFF3F3F3),
                            itemBuilder: (context, item) {
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  // ฝั่งซ้าย: แสดงเกรดเด่นๆ
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.brown.shade400,
                                    child: Text(
                                      item.gradeCode ?? "-",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // ส่วนกลาง: ชื่อฟาร์ม
                                  title: Text(
                                    item.farmName ?? "ไม่ระบุชื่อฟาร์ม",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  // ส่วนล่าง: วันที่เก็บเกี่ยว
                                  subtitle: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(UtilService.formatThaiDate(item.harvestDate ?? DateTime.now())),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('ไม่สามารถโหลดข้อมูลได้'));
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _navigateToRegister(context),
        icon: const Icon(Icons.add, color: Color(0xFFF3F3F3)),
        label: const Text(
          "เพิ่มข้อมูลหน่วยรวบรวม",
          style: TextStyle(color: Color(0xFFF3F3F3), fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF794c46),
        ),
      ),
    );
  }
}

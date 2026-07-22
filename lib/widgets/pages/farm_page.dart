import 'package:cocoa_supply/models/plot_model.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';
import 'package:cocoa_supply/bloc/farm/farm_bloc.dart';
import 'package:cocoa_supply/bloc/farm/farm_event.dart';
import 'package:cocoa_supply/bloc/farm/farm_state.dart';

class FarmPage extends StatefulWidget {
  const FarmPage({super.key});

  @override
  State<FarmPage> createState() => _FarmPageState();
}

class _FarmPageState extends State<FarmPage> {
  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  Future<void> _onRefresh() async {
    context.read<FarmBloc>().add(LoadFarms());
  }

  void _navigateToRegister(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(AppRoute.farmRegister);
    if (result == true) {
      _onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          if (state is FarmLoading || state is FarmInitial) {
            return const Center(child: ThreeDotsLoading());
          } else if (state is FarmsLoaded) {
            final farms = state.farms;
            
            if (farms.isEmpty) {
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
                      'ไม่พบข้อมูล',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100), // เผื่อที่ให้ปุ่ม FAB
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                
                // 🔥 แก้จุดนี้: ดึงจาก farm.plots ตรงๆ ตามโครงสร้างใหม่
                final farmPlots = farm.plots ?? [];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            farm.farmName ?? "",
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
                            'assets/images/farm.jpg',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: DataRecordContainer<Plot>(
                            title: 'แปลงปลูก',
                            subtitle: 'ข้อมูลแปลงล่าสุด',
                            items: farmPlots, // 🔥 ใช้ข้อมูลที่ดึงจาก farm
                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                            cardColor: const Color(0xFFF3F3F3),
                            itemBuilder: (context, item) =>
                                Text(item.plotName ?? "", style:TextStyle(fontSize:18)),
                            onAddData: () async {
                              final result = await Navigator.of(context).pushNamed(
                                AppRoute.plotRegister,
                                arguments: {
                                  'farm_id': farm.farmId
                                },
                              );
                              if (result == true) _onRefresh();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is FarmOperationFailure) {
            return Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${state.error}'),
            );
          }
          return const Center(child: Text('สถานะไม่รู้จัก'));
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _navigateToRegister(context),
        icon: const Icon(Icons.add, color: Color(0xFFF3F3F3)),
        label: const Text(
          "เพิ่มข้อมูลฟาร์ม",
          style: TextStyle(color: Color(0xFFF3F3F3), fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF794c46),
        ),
      ),
    );
  }
}
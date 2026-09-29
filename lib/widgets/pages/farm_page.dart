import 'package:cocoa_supply/models/plot_model.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';
import 'package:cocoa_supply/bloc/farm/farm_bloc.dart';
import 'package:cocoa_supply/bloc/farm/farm_event.dart';
import 'package:cocoa_supply/bloc/farm/farm_state.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/empty_state_view.dart';

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
      backgroundColor: AppColors.surface,
      body: BlocBuilder<FarmBloc, FarmState>(
        builder: (context, state) {
          if (state is FarmLoading || state is FarmInitial) {
            return const Center(child: ThreeDotsLoading());
          } else if (state is FarmsLoaded) {
            final farms = state.farms;
            
            if (farms.isEmpty) {
              return const EmptyStateView(message: 'ไม่พบข้อมูล');
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100), // เผื่อที่ให้ปุ่ม FAB
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                
                // 🔥 แก้จุดนี้: ดึงจาก farm.plots ตรงๆ ตามโครงสร้างใหม่
                final farmPlots = farm.plots ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero photo with the farm name overlaid on a bottom
                      // scrim, instead of a plain caption below it -- the
                      // scrim guarantees white-on-dark contrast regardless
                      // of how bright the photo underneath is.
                      Stack(
                        children: [
                          Image.asset(
                            'assets/images/farm.jpg',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.0),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                              child: Text(
                                farm.farmName ?? "",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: DataRecordContainer<Plot>(
                          title: 'แปลงปลูก',
                          subtitle: 'ข้อมูลแปลงล่าสุด',
                          items: farmPlots, // 🔥 ใช้ข้อมูลที่ดึงจาก farm
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          cardColor: const Color(0xFFF8F6F5),
                          itemBuilder: (context, item) =>
                              Text(item.plotName ?? "", style: Theme.of(context).textTheme.bodyLarge),
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
        label: Text(
          "เพิ่มข้อมูลฟาร์ม",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFFF3F3F3)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }
}
import 'package:cocoa_supply/bloc/processing_station/processing_station.dart';
import 'package:cocoa_supply/models/batch_model.dart';
import 'package:cocoa_supply/models/processing_station_model.dart';
import 'package:cocoa_supply/services/util_service.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';

class ProcessingStationPage extends StatefulWidget {
  const ProcessingStationPage({super.key});

  @override
  State<ProcessingStationPage> createState() => _ProcessingStationPageState();
}

class _ProcessingStationPageState extends State<ProcessingStationPage> {
  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  // แยกฟังก์ชันการดึงข้อมูลออกมา เพื่อเรียกใช้ซ้ำได้ง่าย
  void _onRefresh() {
    context.read<ProcessingStationBloc>().add(LoadProcessingStations());
  }

  // แก้ไขเพื่อให้รองรับการโหลดข้อมูลใหม่หลังจากกลับมาจากหน้า Register
  Future<void> _navigateToRegister(BuildContext context) async {
    await Navigator.of(context).pushNamed(AppRoute.processingStationRegister);

    // เมื่อ Pop กลับมาหน้าเดิม (และ Widget ยังอยู่) ให้โหลดข้อมูลใหม่ทันที
    if (mounted) {
      _onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: BlocBuilder<ProcessingStationBloc, ProcessingStationState>(
        builder: (context, state) {
          if (state is ProcessingStationLoading ||
              state is ProcessingStationInitial) {
            return const Center(child: ThreeDotsLoading());
          }
          if (state is ProcessingStationsLoaded) {
            final stations = state.stations;

            if (stations.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
                  return _buildProcessingStationCard(context, station);
                },
              ),
            );
          }

          return const Center(child: Text('ไม่สามารถแสดงข้อมูลได้'));
        },
      ),
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _navigateToRegister(context),
        icon: const Icon(Icons.add, color: Color(0xFFF3F3F3)),
        label: const Text(
          "เพิ่มข้อมูลสถานีแปรรูป",
          style: TextStyle(color: Color(0xFFF3F3F3), fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF794c46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'ไม่พบข้อมูลสถานีแปรรูป',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStationCard(
    BuildContext context,
    ProcessingStation station,
  ) {
    final batches = station.batches ?? [];
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                station.processingStationName ?? "ไม่มีชื่อสถานี",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/processing_station.jpg',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DataRecordContainer<Batch>(
                title: 'ล๊อต',
                subtitle: 'ข้อมูลล๊อตล่าสุด',
                items: batches,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                cardColor: const Color(0xFFF3F3F3),
                itemBuilder: (context, item) => Text(
                  item.origin ??
                      "" +
                          " " +
                          UtilService.formatThaiDate(
                            item.createdAt ?? DateTime.now(),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

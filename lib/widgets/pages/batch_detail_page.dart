// lib/widgets/pages/batch_detail_page.dart

import 'package:cocoa_supply/bloc/batch/batch.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';

class BatchDetailPage extends StatefulWidget {
  final String batchNo;
  final String processingStationNo;

  const BatchDetailPage({
    super.key, 
    required this.batchNo, 
    required this.processingStationNo
  });

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<BatchBloc>().add(LoadBatchDetail(widget.batchNo, widget.processingStationNo));
  }

  void _navigateToRegister(String tableName) {
    Navigator.of(context).pushNamed(AppRoute.dynamicRegister, arguments: {
      'tableName': tableName,
      'compositeKeyData': {'batch_no': widget.batchNo} // ส่ง batch_no ไป prefill ในฟอร์ม
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: "ข้อมูลล๊อต",
      body: BlocBuilder<BatchBloc, BatchState>(
        builder: (context, state) {
          if (state is BatchLoading) {
            return const Center(child: ThreeDotsLoading());
          }

          if (state is BatchLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 1. ข้อมูลการหมัก (fermentation_batch)
                  DataRecordContainer<dynamic>(
                    title: 'ข้อมูลการหมัก',
                    items: state.fermentations,
                    itemBuilder: (context, item) {
                      final startedAt = item['startedAt'];
                      return Text('หมัก ณ วันที่ ${startedAt ?? "-"}');
                    },
                    onEdit: (item) => _navigateToRegister('fermentation_batch'),
                    // onView: (item) => _navigateToRegister('fermentation_batch'),
                    onAddData: () => _navigateToRegister('fermentation_batch'),
                  ),
                  const SizedBox(height: 16),

                  // 2. ข้อมูลการทำแห้ง (drying_batch)
                  DataRecordContainer<dynamic>(
                    title: 'ข้อมูลการทำแห้ง',
                    items: state.dryings,
                    itemBuilder: (context, item) {
                      final startedAt = item['startedAt'];
                      return Text('ทำแห้ง ณ วันที่ ${startedAt ?? "-"}');
                    },
                    onEdit: (item) => _navigateToRegister('drying_batch'),
                    // onView: (item) => _navigateToRegister('drying_batch'),
                    onAddData: () => _navigateToRegister('drying_batch'),
                  ),
                  const SizedBox(height: 16),

                  // 3. ข้อมูลบันทึกการแปรรูป (processing_record)
                  DataRecordContainer<dynamic>(
                    title: 'ข้อมูลบันทึกการแปรรูป',
                    items: state.records,
                    itemBuilder: (context, item) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${"กิจกรรม"} ${item['recordedAt'] ?? ""}', 
                               style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (item['tempMorningOutside'] != null)
                            Text('อุณหภูมินอกถัง ${item['tempMorningOutside']} องศาเซลเซียส', 
                                 style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      );
                    },
                    onEdit: (item) => _navigateToRegister('processing_record'),
                    // onView: (item) => _navigateToRegister('processing_record'),
                    onAddData: () => _navigateToRegister('processing_record'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('ไม่พบข้อมูลล็อตนี้'));
        },
      ),
    );
  }
}
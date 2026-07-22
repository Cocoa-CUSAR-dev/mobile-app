// lib/widgets/pages/transaction_detail_page.dart

import 'package:cocoa_supply/bloc/transaction/transaction.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/widgets/components/data_record_container.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionDetailPage extends StatefulWidget {
  final String processingStationNo;
  final String transactionNo;
  const TransactionDetailPage({super.key, required this.processingStationNo, required this.transactionNo});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadTransactionDetail(widget.transactionNo));
  }

  void _navigateToRegister(String tableName) {
    Navigator.of(context).pushNamed(AppRoute.dynamicRegister, arguments: {
      'tableName': tableName,
      'compositeKeyData': {
        'processing_station_no' : widget.processingStationNo,
        'transaction_no': widget.transactionNo
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: "รายละเอียดธุรกรรม",
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: ThreeDotsLoading());
          }

          if (state is TransactionLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // 1. ส่วนข้อมูลรายละเอียดธุรกรรม (Price/Weight) 
                  DataRecordContainer<dynamic>(
                    title: 'ข้อมูลน้ำหนักและราคา',
                    items: state.transactionDetails,
                    itemBuilder: (context, item) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('วันที่: ${item['transaction_date'] ?? "-"}'),
                          Text('น้ำหนักรวม: ${item['fresh_cacao_weight_kg']} กก.',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('ราคารวม: ${item['price']} บาท',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      );
                    },
                    onEdit: (item) => _navigateToRegister('transaction_detail'),
                    onAddData: () => _navigateToRegister('transaction_detail'),
                  ),
                  const SizedBox(height: 16),

                  // 2. ส่วนข้อมูลเกรดผลผลิต (Grade Detail) 
                  DataRecordContainer<dynamic>(
                    title: 'ข้อมูลการจัดเกรดคุณภาพ',
                    items: state.gradeDetails,
                    // Try replacing the ListTile section with this to test:
                    itemBuilder: (context, item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('เกรด ${item['grade_code']}', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('ปริมาณ ${item['quantity_kg']} กก.'),
                                ],
                              ),
                            ),
                            Icon(
                              item['is_clean'] == true ? Icons.check_circle : Icons.error,
                              color: item['is_clean'] == true ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                    onEdit: (item) => _navigateToRegister('transaction_grade_detail'),
                    onAddData: () => _navigateToRegister('transaction_grade_detail'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('ไม่พบข้อมูลธุรกรรม'));
        },
      ),
    );
  }
}
// // lib/widgets/pages/plot_detail_page.dart

// import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cocoa_supply/route.dart';
// import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
// import 'package:cocoa_supply/widgets/components/data_record_container.dart';

// import 'package:cocoa_supply/bloc/plot/plot_bloc.dart';
// import 'package:cocoa_supply/bloc/plot/plot_event.dart';
// import 'package:cocoa_supply/bloc/plot/plot_state.dart';
// import 'package:cocoa_supply/models/plot_model.dart';

// class PlotDetailPage extends StatefulWidget {
//   final String farmNo;
//   final int plotSeqNo;

//   const PlotDetailPage({
//     super.key,
//     required this.farmNo,
//     required this.plotSeqNo,
//   });

//   @override
//   State<PlotDetailPage> createState() => _PlotDetailPageState();
// }

// class _PlotDetailPageState extends State<PlotDetailPage> {
//   late final PlotBloc _bloc;

//   @override
//   void initState() {
//     super.initState();
//     _bloc = context.read<PlotBloc>();
//     _bloc.add(LoadPlots());
//   }

//   void _navigateToRegister(BuildContext context, String tableName) {
//     Navigator.of(context).pushNamed(
//       AppRoute.dynamicRegister,
//       arguments: {
//         'tableName': tableName,
//         'compositeKeyData': {
//           'farm_no': widget.farmNo,
//           'plot_seq_no': widget.plotSeqNo.toDouble(),
//         },
//       },
//     );
//   }

//   void _navigateToViewDetail(
//     BuildContext context,
//     String tableName,
//     String itemId,
//   ) {
//     Navigator.of(context).pushNamed(
//       AppRoute.dynamicRegister,
//       arguments: {
//         'tableName': tableName,
//         'compositeKeyData': {
//           'farm_no': widget.farmNo,
//           'plot_seq_no': widget.plotSeqNo.toDouble(),
//         },
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SimpleScaffold(
//       title: 'ข้อมูลแปลง',
//       body: BlocBuilder<PlotBloc, PlotState>(
//         builder: (context, state) {
//           // Loading
//           if (state is PlotLoading) {
//             return const Center(child: ThreeDotsLoading());
//           }
//           // Loaded
//           if (state is PlotsLoaded) {
//             if (state.plots.isEmpty) {
//               return const Center(child: Text('ไม่พบข้อมูลแปลง'));
//             }

//             // ถ้าต้องการกรองตาม farmNo / plotSeqNo
//             final Plot plot = state.plots.first;

//             return _buildContent(context, plot);
//           }

//           // Initial / อื่น ๆ
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }

//   Widget _buildContent(BuildContext context, Plot plot) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//       child: Column(
//         children: [
//           // 1. กิจกรรม
//           DataRecordContainer<String>(
//             title: 'กิจกรรม',
//             items: const ['การเก็บเกี่ยววันที่ 24/05/2568'],
//             itemBuilder: (context, item) => Text(item),
//             onEdit: (item) =>
//                 _navigateToViewDetail(context, 'plot_activity', item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'plot_activity'),
//           ),
//           const SizedBox(height: 12),

//           // 2. ข้อมูลประเมินเชิงเศรษฐกิจ
//           DataRecordContainer<String>(
//             title: 'ข้อมูลประเมินเชิงเศรษฐกิจ',
//             items: const ['ประเมิน ณ วันที่ 12/05/2568'],
//             itemBuilder: (context, item) => Text(item),
//             onEdit: (item) =>
//                 _navigateToViewDetail(context, 'plot_economic_eval', item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'plot_economic_eval'),
//           ),
//           const SizedBox(height: 12),

//           // 3. ข้อมูลการใช้สารเคมี
//           DataRecordContainer<String>(
//             title: 'ข้อมูลการใช้สารเคมี',
//             items: const ['แมนโคเซ็บ (30 กรัม)'],
//             itemBuilder: (context, item) => Text(item),
//             onEdit: (item) =>
//                 _navigateToViewDetail(context, 'plot_activity_chemical', item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'plot_activity_chemical'),
//           ),
//           const SizedBox(height: 12),

//           // 4. ข้อมูลการใช้ปุ๋ย
//           DataRecordContainer<String>(
//             title: 'ข้อมูลการใช้ปุ๋ย',
//             items: const [],
//             itemBuilder: (context, item) => Text(item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'plot_activity_fertilizer'),
//           ),
//           const SizedBox(height: 12),

//           // 5. ข้อมูลการใช้เครื่องมือ
//           DataRecordContainer<String>(
//             title: 'ข้อมูลการใช้เครื่องมือ',
//             items: const ['สปริงเกอร์ (ระบบน้ำ)', 'พลั่ว (ระบบดิน)'],
//             itemBuilder: (context, item) => Text(item),
//             onEdit: (item) =>
//                 _navigateToViewDetail(context, 'farm_tool_inventory', item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'farm_tool_inventory'),
//           ),
//           const SizedBox(height: 12),

//           // 6. ข้อมูลกล้าพันธุ์
//           DataRecordContainer<String>(
//             title: 'ข้อมูลกล้าพันธุ์',
//             items: const [
//               'พันธุ์ชุมพร 1 (พันธุ์หลัก)',
//               'พันธุ์ ICS 95 (พันธุ์รอง)',
//             ],
//             itemBuilder: (context, item) {
//               final bool isMain = item.contains('พันธุ์หลัก');
//               return Text(
//                 item,
//                 style: TextStyle(
//                   color: isMain ? Colors.green : Colors.black87,
//                 ),
//               );
//             },
//             onEdit: (item) =>
//                 _navigateToViewDetail(context, 'plot_breed', item),
//             onAddData: () =>
//                 _navigateToRegister(context, 'plot_breed'),
//           ),

//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }
// }

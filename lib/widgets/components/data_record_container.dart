import 'package:flutter/material.dart';

/// Container for displaying a block of related data (e.g., activity records)
class DataRecordContainer<TItem> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<TItem> items;
  final Widget Function(BuildContext context, TItem item) itemBuilder;
  final void Function(TItem item)? onView; 
  final void Function(TItem item)? onEdit; 
  final VoidCallback? onAddData;

  final BorderRadiusGeometry? borderRadius;
  final Color? cardColor;

  const DataRecordContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.itemBuilder,
    this.onView,
    this.onEdit,
    this.onAddData,
    this.borderRadius,
    this.cardColor,
  });

  @override
  State<DataRecordContainer<TItem>> createState() =>
      _DataRecordContainerState<TItem>();
}

class _DataRecordContainerState<TItem>
    extends State<DataRecordContainer<TItem>> {
  bool _showAll = false;

  void _toggleShowAll() {
    setState(() {
      _showAll = !_showAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณรายการที่จะแสดง
    final itemsToShow = _showAll
        ? widget.items
        : (widget.items.length > 3 ? widget.items.take(3).toList() : widget.items);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: widget.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ให้ Column ใช้พื้นที่เท่าที่จำเป็น
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // ใช้ Expanded กันชื่อยาวเกินแล้วดันปุ่มหลุดขอบ
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.items.length > 3)
                  TextButton(
                    onPressed: _toggleShowAll,
                    child: Text(
                      _showAll ? 'ย่อ' : 'อ่านเพิ่มเติม',
                      style: const TextStyle(color: Color(0xFF794c46)),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24, color: Colors.black26),

            // --- Content Section ---
            if (widget.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('ไม่มีข้อมูล', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.separated( // ใช้ ListView เพื่อความง่าย หรือ Column ก็ได้
                shrinkWrap: true, // สำคัญ: เพื่อให้ ListView อยู่ใน Column ได้
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsToShow.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = itemsToShow[index];
                  return Row(
                    children: [
                      // ส่วนของข้อมูล (Item Builder)
                      Expanded(
                        flex: 3,
                        child: widget.itemBuilder(context, item),
                      ),
                      
                      
                      // เส้นคั่นกลาง (แก้ไขปัญหา Infinite Width)
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(color: Colors.black12),
                        ),
                      ),

                      // ส่วนของปุ่ม Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onEdit != null)
                            IconButton(
                              onPressed: () => widget.onEdit!(item),
                              constraints: const BoxConstraints(), // ลดพื้นที่ว่างรอบไอคอน
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(Icons.edit, color: Color(0xFF794c46), size: 20),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16),

            // --- Footer Button ---
            if (widget.onAddData != null)
              SizedBox(
                width: double.infinity, // ขยายเต็มความกว้าง Card
                child: ElevatedButton(
                  onPressed: widget.onAddData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF794c46),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('ใส่ข้อมูล', style: TextStyle(fontFamily: 'NotoSansThaiLooped', fontSize:18)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
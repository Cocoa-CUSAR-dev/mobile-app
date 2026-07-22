import 'package:flutter/material.dart';

class ThreeDotsLoading extends StatefulWidget {
  final Color color;
  final double size;

  const ThreeDotsLoading({
    super.key,
    // 🔽 ปรับค่า Default เป็นสีน้ำตาล Color(0xFF794c46) ที่คุณต้องการ
    this.color = const Color(0xFF794c46), 
    this.size = 10.0,
  });

  @override
  State<ThreeDotsLoading> createState() => _ThreeDotsLoadingState();
}

class _ThreeDotsLoadingState extends State<ThreeDotsLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // ปรับความเร็วให้พอดี
    )..repeat(reverse: true); // ให้จุดดิ้นขึ้น-ลงแบบนุ่มนวล
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่ตรงกลางเสมอ
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // สร้างความเหลื่อมของจังหวะ (Delay) ระหว่างจุด
            final delay = index * 0.2;
            final animValue = Curves.easeInOut.transform(
              ((_controller.value + delay) % 1.0).clamp(0.0, 1.0),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -3 * animValue), // ระยะที่จุดดิ้นขึ้น
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    // ใช้สีน้ำตาลที่กำหนด พร้อมทำจางสลับเข้มตามจังหวะ
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
import 'package:flutter/material.dart';

/// RootComponent สำหรับหน้าจอที่ต้องการความเรียบง่าย พร้อมภาพพื้นหลังจางๆ
class SimpleScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  
  // เพิ่ม Callback สำหรับทำงานก่อน Pop (เช่น Future<void> หรือ void)
  final Future<void> Function()? onBeforePop;

  const SimpleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.onBeforePop, // รับค่าแบบ Optional
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500, 
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () async {
                  // ถ้ามีการส่ง function มา ให้รอก่อน (await)
                  if (onBeforePop != null) {
                    await onBeforePop!();
                  }
                  
                  // ค่อยสั่ง Pop หลังจากทำงานข้างบนเสร็จ
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          Positioned(
            child: Image.asset(
              'assets/images/bg.png',
              width: 1020,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
    );
  }
}
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileUploadController extends ChangeNotifier {
  PlatformFile? _value;

  // Getter สำหรับดึงค่าไฟล์
  PlatformFile? get value => _value;

  // Setter สำหรับเปลี่ยนค่าและแจ้งเตือน UI (เหมือนการพิมพ์ใน TextField)
  set value(PlatformFile? newValue) {
    _value = newValue;
    notifyListeners(); // แจ้งตัวที่ฟังอยู่ให้ Rebuild
  }

  // ตรวจสอบว่ามีไฟล์หรือไม่
  bool get hasFile => _value != null;

  // ล้างข้อมูลไฟล์
  void clear() {
    _value = null;
    notifyListeners();
  }
}

class UploadInput extends StatelessWidget {
  final String label;
  final FileUploadController controller;

  const UploadInput({super.key, required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label ด้านบน
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'NotoSansThaiLooped',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // ส่วนของ Input Box
            InkWell(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform
                    .pickFiles();
                if (result != null) {
                  controller.value = result.files.first;
                }
              },
              child: Container(
                height: 50, // ขนาดมาตรฐานเท่า TextField ทั่วไป
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFF8F8F8),
                ),
                child: Row(
                  children: [
                    // แสดงชื่อไฟล์ หรือ Placeholder
                    Expanded(
                      child: Text(
                        controller.hasFile
                            ? controller.value!.name
                            : "เลือกไฟล์...",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'NotoSansThaiLooped',
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis, // กันชื่อไฟล์ยาวเกิน
                      ),
                    ),

                    // ไอคอนด้านขวา (เปลี่ยนตามสถานะไฟล์)
                    if (controller.hasFile)
                      GestureDetector(
                        onTap: () => controller.clear(),
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      )
                    else
                      const Icon(
                        Icons.file_upload_outlined,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

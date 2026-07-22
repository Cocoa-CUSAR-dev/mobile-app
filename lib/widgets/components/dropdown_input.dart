import 'package:flutter/material.dart';

class DropdownInput<T, V> extends StatelessWidget {
  final String label;
  final bool isRequired;
  final List<T> items;
  final V? value;
  final ValueChanged<V?> onChanged;
  final String Function(T) itemLabelBuilder;
  final V Function(T) itemValueBuilder;
  final bool isDropdown;
  final String? Function(V?)? validator; // เพิ่ม validator สำหรับเรียกจากภายนอก

  const DropdownInput({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemLabelBuilder,
    required this.itemValueBuilder,
    this.isRequired = false,
    this.isDropdown = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // ใช้ FormField เพื่อจัดการสถานะ Error และ Validation
    return FormField<V>(
      initialValue: value,
      validator: validator ?? (val) {
        if (isRequired && val == null) {
          return 'กรุณาเลือกข้อมูล'; // ข้อความแจ้งเตือน
        }
        return null;
      },
      builder: (FormFieldState<V> state) {
        final bool shouldShowDropdown = isDropdown || items.length > 10;
        final bool hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label, isRequired),
            const SizedBox(height: 8),
            
            // ส่วนแสดงผลหลัก
            shouldShowDropdown 
                ? _buildDropdownMenu(state, hasError) 
                : _buildFullWidthChips(state, hasError),
            
            // แสดงข้อความ Error สีแดงใต้ Input
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// 🔽 ปรับปรุง DropdownMenu ให้แสดงขอบสีแดงเมื่อ Error
  Widget _buildDropdownMenu(FormFieldState<V> state, bool hasError) {
    // หา Label ของค่าที่เลือกอยู่ในปัจจุบัน
    String currentLabel = "กรุณาเลือกรายการ";
    try {
      if (value != null) {
        final selectedItem = items.firstWhere((item) => itemValueBuilder(item) == value);
        currentLabel = itemLabelBuilder(selectedItem);
      }
    } catch (_) {}

    return InkWell(
      onTap: () => _showSearchDialog(state), // เมื่อกดจะเปิด Dialog ค้นหา
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ปรับ padding ให้ใกล้เคียงเดิม
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasError ? Colors.red : Colors.grey.shade300, 
            width: hasError ? 1.5 : 1
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                currentLabel,
                style: TextStyle(
                  fontSize: 18, 
                  color: value == null ? Colors.grey : Colors.black87
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.search, color: hasError ? Colors.red : const Color(0xFF794c46)),
          ],
        ),
      ),
    );
  }

  /// 🔍 ฟังก์ชันแสดง Dialog สำหรับการค้นหา
  void _showSearchDialog(FormFieldState<V> state) {
    showDialog(
      context: state.context,
      builder: (context) {
        List<T> filteredItems = List.from(items);
        
        return StatefulBuilder( // ใช้ StatefulBuilder เพื่ออัปเดตรายการค้นหาใน Dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("ค้นหา $label"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์เพื่อค้นหา...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          filteredItems = items.where((item) {
                            final text = itemLabelBuilder(item).toLowerCase();
                            return text.contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final itemValue = itemValueBuilder(item);
                          final isSelected = value == itemValue;

                          return ListTile(
                            title: Text(itemLabelBuilder(item)),
                            selected: isSelected,
                            trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF794c46)) : null,
                            onTap: () {
                              onChanged(itemValue);
                              state.didChange(itemValue);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    onChanged(null);
                    state.didChange(null);
                    Navigator.pop(context);
                  },
                  child: const Text("ล้างค่า", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ปิด"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  /// 🔽 ปรับปรุง Chips ให้แสดงขอบสีแดงเมื่อ Error
  Widget _buildFullWidthChips(FormFieldState<V> state, bool hasError) {
    if (items.isEmpty && !isDropdown) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("ไม่มีข้อมูลให้เลือก", style: TextStyle(color: Colors.grey, fontSize: 20)),
      );
    }
    return Column(
      children: items.map((T item) {
        final itemValue = itemValueBuilder(item);
        final isSelected = value == itemValue;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              backgroundColor: isSelected ? const Color(0xFF794c46) : const Color(0xFFF8F8F8),
              side: BorderSide(
                // ถ้า Error และยังไม่ได้เลือก ให้ขอบเป็นสีแดง
                color: isSelected 
                    ? Colors.transparent 
                    : (hasError ? Colors.red : Colors.grey.shade300),
                width: hasError ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () {
              final val = isSelected ? null : itemValue;
              onChanged(val);
              state.didChange(val); // อัปเดตสถานะ Validation ทันทีที่กด
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  itemLabelBuilder(item),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 18,
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Colors.white : (hasError ? Colors.red : Colors.grey.shade500),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String label, bool isRequired) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        children: [
          if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
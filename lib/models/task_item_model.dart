import 'package:flutter/material.dart';

class TaskItem {
  final String taskId;       
  final String title;
  final String description;
  final String handler;
  final String status;       // 'COMPLETED', 'OVERDUE', 'NOT_STARTED', 'PENDING'
  final DateTime? openAt;    
  final DateTime? closeAt;   
  final Map<String, dynamic>? answer; 
  // form.task_form.is_multiple_submit: the farmer may file several rows
  // against this task, so a second queued row is not a conflict.
  final bool isMultipleSubmit;

  TaskItem({
    required this.taskId,
    required this.title,
    required this.description,
    required this.handler,
    this.status = 'NOT_STARTED',
    this.openAt,
    this.closeAt,
    this.answer,
    this.isMultipleSubmit = false,
  });

  // --- Logic การแสดงผลภาษาไทย ---

  String get statusText {
    switch (status) {
      case 'COMPLETED':
        return "ดำเนินการแล้ว";
      case 'PENDING':
        return "รออัปโหลด (Offline)";
      case 'IN_PROGRESS':
        return "กำลังดำเนินการ";
      case 'OVERDUE':
        return "เลยกำหนดส่ง";
      case 'NOT_STARTED':
      default:
        return "รอดำเนินการ";
    }
  }

  Color get statusColor {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // เขียว (Success)
      case 'PENDING':
      case 'IN_PROGRESS':
        return const Color(0xFF2196F3); // น้ำเงิน (Info/Sync)
      case 'OVERDUE':
        return const Color(0xFFF44336); // แดง (Error)
      case 'NOT_STARTED':
      default:
        return const Color(0xFFFF9800); // ส้ม (Warning)
    }
  }

  // ใช้สำหรับเช็กว่า Task นี้แก้ไขได้หรือไม่
  bool get canEdit => status != 'OVERDUE';

  // --- Factory สำหรับรับข้อมูลจาก Go API ---
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      taskId: json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      handler: json['handler'] ?? '', 
      status: json['status'] ?? 'NOT_STARTED',
      openAt: json['open_at'] != null ? DateTime.parse(json['open_at']) : null,
      closeAt: json['close_at'] != null ? DateTime.parse(json['close_at']) : null,
      answer: json['answer'],
      isMultipleSubmit: json['is_multiple_submit'] == true,
    );
  }

  // เพิ่ม method สำหรับเปลี่ยนสถานะเป็น PENDING เมื่อบันทึกลง Local DB (เช่น SQLite)
  TaskItem copyWithPending(Map<String, dynamic> newAnswer) {
    return TaskItem(
      taskId: taskId,
      title: title,
      description: description,
      handler: handler,
      status: 'PENDING',
      openAt: openAt,
      closeAt: closeAt,
      answer: newAnswer,
      isMultipleSubmit: isMultipleSubmit,
    );
  }
}
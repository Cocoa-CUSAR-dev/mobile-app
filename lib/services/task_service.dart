// lib/services/task_service.dart

import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TaskService {
  static const String _storageKey = 'tasks_data';
  static const String _endpoint = '/tasks';

  TaskService({http.Client? client})
    : _provider = ServiceProvider<TaskItem>(
        storageKey: _storageKey,
        endpoint: _endpoint,
        isRealApi: true,
        client: client,
      );

  final ServiceProvider<TaskItem> _provider;

  /// ดึงข้อมูลงานทั้งหมดตามวันที่ระบุ
  Future<List<TaskItem>> getTasksByDate(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return _provider.fetchData(
      TaskItem.fromJson,
      queryParams: {'date': formattedDate},
    );
  }

  /// ดึงข้อมูลคำตอบที่เคยส่งไปแล้ว (Response) ตาม taskId
  /// เพื่อนำมา Initialize ในหน้าฟอร์ม
  Future<Map<String, dynamic>?> getTaskResponse(String taskId) async {
    try {
      // เรียกเส้น GET /tasks/:taskId ใน Go ซึ่งจะคืนค่า answer ก้อนใหญ่กลับมา
      final response = await _provider.fetchOne(taskId);
      return response; 
    } catch (e) {
      print("No previous response found for task: $taskId");
      return null;
    }
  }

  /// ส่งงานใหม่ (POST) - Payload ตรงตาม Go Struct: { "task_id": "...", "answer": {...} }
  Future<void> submitTask(String taskId, Map<String, dynamic> answer) async {
    final payload = {
      'task_id': taskId,
      'answer': answer,
    };
    await _provider.postData(payload);
  }

  /// แก้ไขงาน (PUT) - Payload ตรงตาม Go Struct: { "task_id": "...", "answer": {...} }
  Future<void> updateTask(String taskId, Map<String, dynamic> answer) async {
    final payload = {
      'task_id': taskId,
      'answer': answer,
    };
    // เรียก putData แบบใหม่ที่ไม่ต้องส่ง ID ใน URL
    print('UPDATE TASK;!!');
    await _provider.putData(payload);
  }

  /// ลบข้อมูลงาน
  Future<void> deleteTask(String taskId) async {
    await _provider.deleteData(taskId);
  }
}
// lib/services/task_service.dart

import 'package:cocoa_supply/models/task_item_model.dart';
import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TaskService {
  static const String _storageKey = 'tasks_data';
  static const String _endpoint = ApiEndpoints.tasks;

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

  /// ส่งงานใหม่ (POST /tasks/:taskId/responses) -- task id อยู่ใน URL, body มีแค่ answer
  Future<void> submitTask(String taskId, Map<String, dynamic> answer) async {
    await _provider.postData({'answer': answer}, pathSuffix: '$taskId/responses');
  }

  /// แก้ไขคำตอบล่าสุดของงานนี้ (PUT /tasks/:taskId/responses/:responseId)
  ///
  /// backend แก้ทีละคำตอบตาม id ส่วนแอปแก้ "คำตอบล่าสุด" จึงต้องถามก่อนว่าคำตอบ
  /// ล่าสุดของงานนี้คืออันไหน (GET /tasks/:taskId/responses เรียงใหม่สุดก่อน)
  Future<void> updateTask(String taskId, Map<String, dynamic> answer) async {
    final responses = await _provider.fetchListAt('$taskId/responses');
    final Object? responseId = responses.isEmpty ? null : responses.first['response_id'];
    if (responseId == null) {
      throw ServerRejection(404, 'ไม่พบคำตอบเดิมของงานนี้ให้แก้ไข');
    }
    await _provider.putData({'answer': answer}, pathSuffix: '$taskId/responses/$responseId');
  }
}
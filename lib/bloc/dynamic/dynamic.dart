// lib/bloc/dynamic/dynamic_bloc.dart
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';

// Events & States
abstract class DynamicEvent {}

class LoadSchemaAndData extends DynamicEvent {
  final String handler;
  final String taskId;
  LoadSchemaAndData(this.handler, this.taskId);
}

class SubmitForm extends DynamicEvent {
  final String handler;
  final String taskId;
  final Map<String, dynamic> data;
  final bool isEdit;
  final bool isDraft;
  SubmitForm({
    required this.handler,
    required this.taskId,
    required this.data,
    this.isEdit = false,
    this.isDraft = false,
  });
}

abstract class DynamicState {}

class DynamicInitial extends DynamicState {}

class DynamicLoading extends DynamicState {}

class DynamicReady extends DynamicState {
  final Map<String, dynamic> form;

  DynamicReady(this.form);
}

class DynamicSuccess extends DynamicState {}

class DynamicError extends DynamicState {
  final String message;
  DynamicError(this.message);
}

// Bloc Implementation
class DynamicBloc extends Bloc<DynamicEvent, DynamicState> {
  final TaskBloc taskBloc;
  final api = DynamicApiService();
  DynamicBloc({required this.taskBloc}) : super(DynamicInitial()) {
    on<LoadSchemaAndData>((event, emit) async {
      emit(DynamicLoading());
      try {
        // 1. โหลดโครงสร้างฟอร์มสด (แทน assets/schema.json เดิม) — แคชในเครื่องให้อัตโนมัติ
        final result = await api.fetchTaskForm(event.taskId);
        final form = result['form'] as Map<String, dynamic>?;

        if (form == null) throw "ไม่พบโครงสร้างฟอร์มสำหรับงานนี้";

        // 2. สั่ง TaskBloc ให้ไปหาคำตอบเก่ามาเตรียมไว้ใน State
        taskBloc.add(GetTaskResponseDetails(event.taskId));

        emit(DynamicReady(form));
      } catch (e) {
        emit(DynamicError(e.toString()));
      }
    });

    on<SubmitForm>((event, emit) async {
      emit(DynamicLoading());
      try {
        // ใช้ฟอร์มเดียวกับที่โหลดไว้แล้ว (แคช ServiceProvider ทำให้เร็ว ไม่ยิงซ้ำจริง)
        final result = await api.fetchTaskForm(event.taskId);
        final form = result['form'] as Map<String, dynamic>? ?? {};
        final sections = (form['sections'] as List<dynamic>? ?? []);

        final Map<String, dynamic> payload = {};
        for (final sectionRaw in sections) {
          final section = sectionRaw as Map<String, dynamic>;
          final questions = (section['questions'] as List<dynamic>? ?? []);
          for (final questionRaw in questions) {
            final question = questionRaw as Map<String, dynamic>;
            final fieldName = question['fieldName'] as String?;
            if (fieldName == null) continue;
            payload[fieldName] = _parseValue(
              event.data[fieldName],
              question['inputType'] as String?,
            );
          }
        }

        // ส่งงานผ่าน TaskBloc
        taskBloc.add(
          SubmitTaskAction(
            event.taskId,
            event.handler,
            payload,
            isDraft: event.isDraft,
            isEdit: event.isEdit,
          ),
        );

        emit(DynamicSuccess());
      } catch (e) {
        emit(DynamicError(e.toString()));
      }
    });
  }

  dynamic _parseValue(dynamic value, String? inputType) {
    if (value == null || value.toString().isEmpty) return null;
    switch (inputType) {
      case 'INT':
        return int.tryParse(value.toString());
      case 'FLOAT':
        return double.tryParse(value.toString());
      case 'BOOLEAN':
        return value is bool ? value : value.toString().toLowerCase() == 'true';
      default:
        // VARCHAR, OPTION (submits the selected choice's id), DATE,
        // DATETIME, GEODATA all pass through as-is (matches prior behaviour).
        return value.toString();
    }
  }
}

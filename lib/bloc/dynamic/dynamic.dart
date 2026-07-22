// lib/bloc/dynamic/dynamic_bloc.dart
import 'dart:convert';
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
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

class LoadDropdownOptions extends DynamicEvent {
  final String key;
  LoadDropdownOptions(this.key);
}

abstract class DynamicState {}

class DynamicInitial extends DynamicState {}

class DynamicLoading extends DynamicState {}

class DynamicReady extends DynamicState {
  final Map<String, dynamic> schema;
  final Map<String, List<Map<String, dynamic>>> dropdownOptions;

  DynamicReady(this.schema, {this.dropdownOptions = const {}});
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
        // 1. โหลดโครงสร้างฟอร์ม
        final String schemaString = await rootBundle.loadString(
          'assets/schema.json',
        );
        final Map<String, dynamic> spec = json.decode(schemaString);
        final schema = spec['definitions'][event.handler];

        if (schema == null) throw "ไม่พบโครงสร้างฟอร์มสำหรับ: ${event.handler}";

        // 2. สั่ง TaskBloc ให้ไปหาคำตอบเก่ามาเตรียมไว้ใน State
        taskBloc.add(GetTaskResponseDetails(event.taskId));

        emit(DynamicReady(schema));
      } catch (e) {
        emit(DynamicError(e.toString()));
      }
    });

    on<SubmitForm>((event, emit) async {
      emit(DynamicLoading());
      try {
        final String response = await rootBundle.loadString(
          'assets/schema.json',
        );
        final schema = json.decode(response)['definitions'][event.handler];
        final Map<String, dynamic> properties = Map<String, dynamic>.from(
          schema['properties'],
        );
        final Map<String, dynamic> payload = {};

        for (final key in properties.keys) {
          final field = properties[key] ?? {};
          if (field['is_key'] == true) {
            payload[key] = event.isEdit ? event.data[key] : const Uuid().v4();
            continue;
          }
          payload[key] = _parseValue(event.data[key], field['type']);
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

  dynamic _parseValue(dynamic value, String? type) {
    if (value == null || value.toString().isEmpty) return null;
    if (type == 'integer') return int.tryParse(value.toString());
    if (type == 'number' || type == 'numeric')
      return double.tryParse(value.toString());
    return value.toString();
  }
}

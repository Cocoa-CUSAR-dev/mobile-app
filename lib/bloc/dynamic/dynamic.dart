// lib/bloc/dynamic/dynamic_bloc.dart
import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/services/dynamic_api_service.dart';
import 'package:cocoa_supply/services/task_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_event.dart';
import 'package:cocoa_supply/bloc/dynamic/parse_field_value.dart';

// Events & States
abstract class DynamicEvent {}

class LoadSchemaAndData extends DynamicEvent {
  final String handler;
  final String taskId;
  LoadSchemaAndData(this.handler, this.taskId);
}

// The farmer answered the "ใช้ข้อมูลเดิม?" sheet (either way, or dismissed
// it). The page has already applied the answers if they accepted; this just
// clears the offer from state so it is shown once, not on every rebuild.
class AutofillOfferHandled extends DynamicEvent {}

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
  // US2-5: set only when this is a new submission with a usable last answer
  // to offer (see DynamicBloc._findAutofillOffer). Null = open as today.
  final AutofillOffer? autofillOffer;

  DynamicReady(this.form, {this.autofillOffer});
}

class DynamicSuccess extends DynamicState {}

class DynamicError extends DynamicState {
  final String message;
  DynamicError(this.message);
}

// Bloc Implementation
class DynamicBloc extends Bloc<DynamicEvent, DynamicState> {
  final TaskBloc taskBloc;
  final DynamicApiService api;
  final TaskService _taskService;
  // Named apiOverride (not api) so it doesn't shadow the `api` field inside
  // this constructor's body — the on<...> closures below reference `api`
  // meaning `this.api`, and a same-named parameter would silently shadow
  // that for the whole constructor scope, not just the initializer list.
  DynamicBloc({
    required this.taskBloc,
    DynamicApiService? apiOverride,
    TaskService? taskServiceOverride,
  }) : api = apiOverride ?? DynamicApiService(),
       _taskService = taskServiceOverride ?? TaskService(),
       super(DynamicInitial()) {
    on<LoadSchemaAndData>((event, emit) async {
      emit(DynamicLoading());
      try {
        // 1. โหลดโครงสร้างฟอร์มสด (แทน assets/schema.json เดิม) — แคชในเครื่องให้อัตโนมัติ
        final result = await api.fetchTaskForm(event.taskId);
        final form = result['form'] as Map<String, dynamic>?;

        if (form == null) throw "ไม่พบโครงสร้างฟอร์มสำหรับงานนี้";

        // 2. สั่ง TaskBloc ให้ไปหาคำตอบเก่ามาเตรียมไว้ใน State
        // ฟอร์มส่งได้หลายครั้ง = กำลังเริ่มแถวใหม่ ใช้คำตอบเดิมเฉพาะข้อที่ติ๊ก carryForward
        taskBloc.add(GetTaskResponseDetails(
          event.taskId,
          onlyFields: form['isMultipleSubmit'] == true ? _carryForwardFields(form) : null,
        ));

        // The form opens NOW, never waiting on the autofill call below --
        // a slow or dead network must cost the farmer nothing.
        final ready = DynamicReady(form);
        emit(ready);

        final offer = await _findAutofillOffer(event.taskId, form);
        // This bloc is app-wide: only show the offer if nothing has happened
        // since -- the farmer may already have submitted, or left and opened
        // a different task, while the request was in flight.
        if (offer != null && identical(state, ready)) {
          emit(DynamicReady(form, autofillOffer: offer));
        }
      } catch (e) {
        emit(DynamicError(e.toString()));
      }
    });

    on<AutofillOfferHandled>((event, emit) {
      final current = state;
      if (current is DynamicReady && current.autofillOffer != null) {
        emit(DynamicReady(current.form));
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
            payload[fieldName] = parseFieldValue(
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

  // US2-5: should this opening of the form offer last time's answers?
  // Follows the design doc's §3.2 table exactly, local checks first so a
  // farmer with a draft never waits on (or even triggers) a network call:
  //
  //   draft for this task                -> no offer (draft wins)
  //   queued row for this task           -> no offer (single-submit: edit
  //                                         mode; multi-submit: not row 1)
  //   multi-submit, task already has a
  //   row on the server                  -> no offer (carry-forward covers
  //                                         later rows; two sources would mix)
  //   single-submit answered on server   -> Go answers 204 -> no offer
  //   otherwise                          -> GET /tasks/:id/autofill, offer on 200
  //   offline / error / 204              -> no offer, blank form
  Future<AutofillOffer?> _findAutofillOffer(String taskId, Map<String, dynamic> form) async {
    if (await taskBloc.hasQueuedItemFor(taskId)) return null;

    if (form['isMultipleSubmit'] == true &&
        await _taskService.getTaskResponse(taskId) != null) {
      return null;
    }

    final response = await api.fetchAutofill(taskId);
    if (response == null) return null;
    return AutofillOffer.fromResponse(response, form);
  }

  // fieldName ของทุกคำถามที่ researcher ติ๊ก "Reuse answer" (carryForward)
  static Set<String> _carryForwardFields(Map<String, dynamic> form) {
    final fields = <String>{};
    for (final sectionRaw in (form['sections'] as List<dynamic>? ?? [])) {
      final section = sectionRaw as Map<String, dynamic>;
      for (final questionRaw in (section['questions'] as List<dynamic>? ?? [])) {
        final question = questionRaw as Map<String, dynamic>;
        final fieldName = question['fieldName'] as String?;
        if (fieldName != null && question['carryForward'] == true) fields.add(fieldName);
      }
    }
    return fields;
  }
}

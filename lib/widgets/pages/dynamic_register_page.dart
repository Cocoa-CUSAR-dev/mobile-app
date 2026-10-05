import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// Blocs
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/dynamic/autofill_offer.dart';
import 'package:cocoa_supply/bloc/dynamic/form_questions.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';

// Components
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';
import 'package:cocoa_supply/widgets/components/autofill_offer_sheet.dart';
import 'package:cocoa_supply/widgets/components/autofill_offer_banner.dart';
import 'package:cocoa_supply/widgets/components/submit_result_view.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

class DynamicRegisterPage extends StatefulWidget {
  final String handler;
  final String taskId;
  final String status;

  const DynamicRegisterPage({
    super.key,
    required this.handler,
    required this.taskId,
    required this.status,
  });

  @override
  _DynamicRegisterPageState createState() => _DynamicRegisterPageState();
}

class _DynamicRegisterPageState extends State<DynamicRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _currentFormData = {};

  int _currentStep = 0;
  final int _fieldsPerPage = 1;
  bool _isDataInitialized = false;
  bool _isLoading = false;
  // US2-5: the "ใช้ข้อมูลเดิม?" sheet pops up by itself at most once per
  // opening; after that the offer waits in a banner until handled.
  bool _autofillOfferSeen = false;
  bool _autofillSheetOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<DynamicBloc>().add(LoadSchemaAndData(widget.handler, widget.taskId));
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ใส่คำตอบที่มีอยู่แล้วลงฟอร์ม -- ทางเดียวที่ใช้ทั้งตอนเปิดแก้ไขงานเดิม/ร่าง
  // (TaskBloc ส่งคำตอบเก่ามา) และตอนกด "ใช้ข้อมูลเดิม" (US2-5) จึงแปลง/ใส่ค่า
  // แบบเดียวกันเสมอ ไม่มีทางที่สองที่ใส่ค่าไม่เหมือนกัน
  //
  // onlyEmpty: ใส่เฉพาะช่องที่ยังว่าง -- ใช้กับข้อเสนอ "ใช้ข้อมูลเดิม" ที่อาจกดจาก
  // แบนเนอร์หลังเกษตรกรเริ่มกรอกไปแล้ว สิ่งที่พิมพ์เองต้องไม่ถูกทับ
  void _applyPrefill(Map<String, dynamic> answer, {bool onlyEmpty = false}) {
    final toApply = onlyEmpty
        ? {for (final e in answer.entries) if (_isEmptyField(e.key)) e.key: e.value}
        : answer;
    _currentFormData.addAll(toApply);
    // The form usually renders before the saved answer arrives,
    // so text controllers already exist (empty) -- fill them too.
    toApply.forEach((k, v) {
      if (v != null) _controllers[k]?.text = v.toString();
    });
    _isDataInitialized = true;
  }

  bool _isEmptyField(String key) {
    final controller = _controllers[key];
    if (controller != null && controller.text.trim().isNotEmpty) return false;
    final value = _currentFormData[key];
    return value == null || (value is String && value.isEmpty) || (value is List && value.isEmpty);
  }

  // ยังไม่ได้เริ่มกรอกอะไรเลย -- ข้อเสนอที่มาช้า (เน็ตช้า) ต้องไม่ไปทับสิ่งที่
  // เกษตรกรเริ่มพิมพ์ไปแล้ว ถ้าเริ่มแล้วก็ไม่ต้องถาม
  bool get _formIsUntouched =>
      _currentStep == 0 &&
      _currentFormData.isEmpty &&
      _controllers.values.every((c) => c.text.trim().isEmpty);

  // The offer can arrive a moment after the form opens. If the farmer hasn't
  // touched anything yet it pops up straight away; if they have, a popup
  // jumping in front of them would be in the way, so it waits in a banner
  // at the top of the form instead (AutofillOfferBanner) -- never discarded.
  void _maybeOfferAutofill(DynamicReady state) {
    final offer = state.autofillOffer;
    if (offer == null || _autofillOfferSeen) return;
    _autofillOfferSeen = true;
    if (_formIsUntouched) _openAutofillOffer(offer);
  }

  Future<void> _openAutofillOffer(AutofillOffer offer) async {
    final dynamicBloc = context.read<DynamicBloc>();
    setState(() => _autofillSheetOpen = true);
    final accepted = await AutofillOfferSheet.show(context, offer);
    if (!mounted) return;
    setState(() {
      _autofillSheetOpen = false;
      // Only fills the form -- nothing is submitted, every field stays
      // editable, and anything the farmer already typed is kept.
      if (accepted) _applyPrefill(offer.answer, onlyEmpty: true);
    });
    // Only USING the offer is final. "เริ่มใหม่" or just closing the sheet
    // leaves the form blank but keeps the offer in the banner, so a farmer
    // who changes their mind halfway through can still take it -- the
    // banner's ✕ is the way to drop it for good.
    if (accepted) dynamicBloc.add(AutofillOfferHandled());
  }

  // --- Logic เช็คความครบถ้วนของข้อมูลเพื่อเปิดปุ่ม 'ถัดไป' ---
  bool _isCurrentStepValid(List<Map<String, dynamic>> currentQuestions) {
    for (var question in currentQuestions) {
      final key = question['fieldName'] as String;
      final bool isRequired = question['isMandatory'] == true;
      if (!isRequired) continue;

      final String inputType = (question['inputType'] as String?) ?? 'VARCHAR';

      // กลุ่มที่ใช้ Controller
      if (!['GEODATA', 'BOOLEAN', 'OPTION'].contains(inputType)) {
        if (_controllers[key]?.text.trim().isEmpty ?? true) return false;
      }
      // กลุ่มที่เก็บใน FormData Direct
      else {
        final value = _currentFormData[key];
        if (value == null) return false;
        if (value is List && value.isEmpty) return false;
        if (value is String && value.isEmpty) return false;
      }
    }
    return true;
  }

  // --- Core Dynamic Dispatcher (เรียกใช้ FormHelper) ---
  Widget _buildDynamicControl(Map<String, dynamic> question) {
    final String key = question['fieldName'] as String;
    final String label = (question['label'] as String?) ?? key;
    final String inputType = (question['inputType'] as String?) ?? 'VARCHAR';
    final bool isReq = question['isMandatory'] == true;

    // 1. Initialize Controllers for text-based inputs
    if (!_controllers.containsKey(key) &&
        !['GEODATA', 'BOOLEAN', 'OPTION'].contains(inputType)) {
      _controllers[key] = TextEditingController(text: _currentFormData[key]?.toString() ?? '');
    }

    // 2. Dispatch to Helper
    switch (inputType) {
      case 'BOOLEAN':
        return FormHelper.buildCheckbox(
          label: label,
          value: _currentFormData[key] == true || _currentFormData[key] == 'true',
          onChanged: (v) => setState(() => _currentFormData[key] = v),
        );

      case 'INT':
      case 'FLOAT':
        return FormHelper.buildNumber(
          label: label,
          controller: _controllers[key]!,
          isReq: isReq,
          isInt: inputType == 'INT',
        );

      case 'DATE':
      case 'DATETIME':
        return FormHelper.buildDate(
          label: label,
          controller: _controllers[key]!,
          isReq: isReq,
          isTime: inputType == 'DATETIME',
        );

      case 'GEODATA':
        final List<LatLng> points = (_currentFormData[key] as List?)
            ?.map((p) => LatLng(p['lat'], p['lng']))
            .toList() ?? [];
        return FormHelper.buildGIS(
          label: label,
          isReq: isReq,
          points: points,
          areaM2: (_currentFormData['${key}_area_m2'] ?? 0.0) as double,
          onChanged: (newData) => setState(() {
            _currentFormData[key] = newData.points.isEmpty
                ? null
                : newData.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
            _currentFormData['${key}_area_m2'] = newData.areaM2;
          }),
        );

      case 'OPTION':
        // choices มากับ question อยู่แล้ว ({id, name} ต่อรายการ) — ไม่ต้อง fetch แยก
        final choices = ((question['choices'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
        return FormHelper.buildDropdown(
          label: label,
          isReq: isReq,
          options: choices,
          currentValue: _currentFormData[key],
          onChanged: (val) => setState(() => _currentFormData[key] = val),
        );

      default:
        // VARCHAR และอื่นๆ ที่ไม่รู้จัก
        return FormHelper.buildInput(
          label: label,
          controller: _controllers[key]!,
          isReq: isReq,
          isTextArea: label.contains('หมายเหตุ') || label.contains('อธิบาย'),
          onChanged: () => setState(() {}),
        );
    }
  }

  // isDraft: เก็บไว้ในเครื่องอย่างเดียว ไม่ส่งขึ้น server (sync ข้ามร่างเสมอ)
  // บันทึกซ้ำจะแทนที่ร่างเดิมของงานนี้ เปิดฟอร์มครั้งหน้าจะได้ร่างนี้กลับมา
  void _onSave({bool isDraft = false}) {
    final data = Map<String, dynamic>.from(_currentFormData);
    _controllers.forEach((k, v) => data[k] = v.text.trim().isEmpty ? null : v.text.trim());

    context.read<DynamicBloc>().add(SubmitForm(
      handler: widget.handler,
      taskId: widget.taskId,
      data: data,
      isEdit: widget.status == 'COMPLETED',
      isDraft: isDraft,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      body: MultiBlocListener(
        listeners: [
          BlocListener<DynamicBloc, DynamicState>(
            listener: (context, state) {
              if (state is DynamicSuccess) Navigator.pop(context, true);
              setState(() => _isLoading = state is DynamicLoading);
              if (state is DynamicReady) _maybeOfferAutofill(state);
            },
          ),
          BlocListener<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state.currentTaskResponse != null && !_isDataInitialized) {
                setState(() => _applyPrefill(state.currentTaskResponse!));
              }
            },
          ),
        ],
        child: BlocBuilder<DynamicBloc, DynamicState>(
          builder: (context, state) {
            if (state is DynamicError) return Center(child: Text(state.message));
            // Also while a submission is being sent -- it used to render
            // nothing here once a prefilled form was submitting.
            if (state is DynamicLoading) return const Center(child: ThreeDotsLoading());
            if (state is DynamicSubmitted) {
              return SubmitResultView(
                result: state.result,
                onDone: () => Navigator.pop(context, true),
              );
            }

            if (state is DynamicReady) {
              final displayQuestions = flattenActiveQuestions(state.form);

              int totalSteps = (displayQuestions.length / _fieldsPerPage).ceil();
              int startIndex = _currentStep * _fieldsPerPage;
              int endIndex = min(startIndex + _fieldsPerPage, displayQuestions.length);
              final currentQuestions = displayQuestions.sublist(startIndex, endIndex);

              bool canProceed = _isCurrentStepValid(currentQuestions);

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (state.autofillOffer != null && !_autofillSheetOpen) ...[
                              AutofillOfferBanner(
                                offer: state.autofillOffer!,
                                onOpen: () => _openAutofillOffer(state.autofillOffer!),
                                onDismiss: () => context.read<DynamicBloc>().add(AutofillOfferHandled()),
                              ),
                              const SizedBox(height: 24),
                            ],
                            _buildStepIndicator(totalSteps),
                            const SizedBox(height: 32),
                            Text(
                              'บันทึกข้อมูล',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ...currentQuestions.map(_buildDynamicControl),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomButtons(
                    isLastStep: (_currentStep + 1) >= totalSteps,
                    canProceed: canProceed,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int totalSteps) {
    if (totalSteps <= 1) return const SizedBox.shrink();
    return Column(
      children: [
        Text("หน้า ${_currentStep + 1} จาก $totalSteps", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentStep == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentStep == i ? AppColors.primary : Colors.grey.shade300,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildBottomButtons({required bool isLastStep, required bool canProceed}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: (canProceed && !_isLoading)
                ? () {
                    if (_formKey.currentState!.validate()) {
                      if (isLastStep) {
                        _onSave();
                      } else {
                        setState(() => _currentStep++);
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLastStep ? 'บันทึกข้อมูล' : 'ถัดไป', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          // ร่างกรอกยังไม่ครบก็เก็บได้ จึงไม่ต้องผ่าน validate
          OutlinedButton(
            onPressed: _isLoading ? null : () => _onSave(isDraft: true),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFF794c46)),
            ),
            child: Text('บันทึกแบบร่าง', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF794c46))),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text(
              _currentStep > 0 ? 'ย้อนกลับ' : 'ยกเลิก',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87)
            ),
          ),
        ],
      ),
    );
  }
}

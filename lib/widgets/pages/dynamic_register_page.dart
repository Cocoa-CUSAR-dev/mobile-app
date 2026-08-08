import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// Blocs
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/bloc/task/task_bloc.dart';
import 'package:cocoa_supply/bloc/task/task_state.dart';

// Components
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';

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

  // ไล่ sections[] -> questions[] ตาม sortOrder ให้เป็น list เดียว
  // ข้าม section/question ที่ isActive == false (researcher ปิดการมองเห็นไว้)
  List<Map<String, dynamic>> _flattenQuestions(Map<String, dynamic> form) {
    final sections = ((form['sections'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((s) => s['isActive'] != false)
        .toList()
      ..sort((a, b) => ((a['sortOrder'] ?? 0) as num).compareTo((b['sortOrder'] ?? 0) as num));

    final questions = <Map<String, dynamic>>[];
    for (final section in sections) {
      final sectionQuestions = ((section['questions'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .where((q) => q['isActive'] != false && q['fieldName'] != null)
          .toList()
        ..sort((a, b) => ((a['sortOrder'] ?? 0) as num).compareTo((b['sortOrder'] ?? 0) as num));
      questions.addAll(sectionQuestions);
    }
    return questions;
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
          value: _currentFormData[key] ?? false,
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

  void _onSave() {
    final data = Map<String, dynamic>.from(_currentFormData);
    _controllers.forEach((k, v) => data[k] = v.text.trim().isEmpty ? null : v.text.trim());

    context.read<DynamicBloc>().add(SubmitForm(
      handler: widget.handler,
      taskId: widget.taskId,
      data: data,
      isEdit: widget.status == 'COMPLETED',
      isDraft: false,
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
            },
          ),
          BlocListener<TaskBloc, TaskState>(
            listener: (context, state) {
              if (state.currentTaskResponse != null && !_isDataInitialized) {
                setState(() {
                  _currentFormData.addAll(state.currentTaskResponse!);
                  _isDataInitialized = true;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<DynamicBloc, DynamicState>(
          builder: (context, state) {
            if (state is DynamicError) return Center(child: Text(state.message));
            if (state is DynamicLoading && !_isDataInitialized) return const Center(child: ThreeDotsLoading());

            if (state is DynamicReady) {
              final displayQuestions = _flattenQuestions(state.form);

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
                            _buildStepIndicator(totalSteps),
                            const SizedBox(height: 32),
                            Text(
                              'บันทึกข้อมูล',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF794c46)
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
        Text("หน้า ${_currentStep + 1} จาก $totalSteps", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentStep == i ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentStep == i ? const Color(0xFF794c46) : Colors.grey.shade300,
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
              backgroundColor: const Color(0xFF794c46),
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLastStep ? 'บันทึกข้อมูล' : 'ถัดไป', style: const TextStyle(color: Colors.white, fontSize: 18)),
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
              style: const TextStyle(fontSize: 18, color: Colors.black87)
            ),
          ),
        ],
      ),
    );
  }
}

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
import 'package:cocoa_supply/widgets/components/upload_input.dart';
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
  final Map<String, FileUploadController> _fileControllers = {};
  final Map<String, dynamic> _currentFormData = {};
  final Map<String, List<Map<String, dynamic>>> _dropdownOptions = {};

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

  // --- Logic เช็คความครบถ้วนของข้อมูลเพื่อเปิดปุ่ม 'ถัดไป' ---
  bool _isCurrentStepValid(List<MapEntry<String, dynamic>> currentFields) {
    for (var field in currentFields) {
      final key = field.key;
      final prop = field.value;
      final bool isRequired = prop['is_required'] ?? false;

      final String type = prop['type'] ?? '';
      if (!isRequired || type != 'string') continue;

      

      // กลุ่มที่ใช้ Controller
      if (['string', 'integer', 'number', 'numeric', 'date', 'datetime', 'timestamp'].contains(type) && !key.endsWith('_id')) {
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

  // --- Dropdown Data Fetching ---
  Future<List<Map<String, dynamic>>> _getOptions(String key) async {
    if (_dropdownOptions.containsKey(key)) return _dropdownOptions[key]!;
    try {
      final dynamicBloc = context.read<DynamicBloc>();
      var data = await dynamicBloc.api.fetchConstants(key);
      if (data.isEmpty) {
        data = await dynamicBloc.api.fetchData(key.replaceAll("_id", ""));
      }
      if (!mounted) return [];
      setState(() => _dropdownOptions[key] = data);
      return data;
    } catch (e) {
      return [];
    }
  }

  // --- Core Dynamic Dispatcher (เรียกใช้ FormHelper) ---
  Widget _buildDynamicControl(String key, Map<String, dynamic> prop) {
    String label = prop['description']?.split('\n')[0] ?? key;
    String type = prop['type'] ?? 'string';
    bool isReq = prop['is_required'] ?? false;

    if (prop['is_from_input'] != true) return const SizedBox.shrink();

    // 1. Initialize Controllers for text-based inputs
    if (!_controllers.containsKey(key) && 
        !['file', 'gis', 'boolean', 'option'].contains(type) && 
        !key.endsWith('_id')) {
      _controllers[key] = TextEditingController(text: _currentFormData[key]?.toString() ?? '');
    }

    // 2. Dispatch to Helper
    switch (type) {
      case 'boolean':
        return FormHelper.buildCheckbox(
          label: label,
          value: _currentFormData[key] ?? false,
          onChanged: (v) => setState(() => _currentFormData[key] = v),
        );

      case 'file':
        _fileControllers.putIfAbsent(key, () => FileUploadController());
        return FormHelper.buildUpload(
          label: label,
          controller: _fileControllers[key]!,
        );

      case 'integer':
      case 'number':
      case 'numeric':
        return FormHelper.buildNumber(
          label: label,
          controller: _controllers[key]!,
          isReq: isReq,
          isInt: type == 'integer',
        );

      case 'date':
      case 'datetime':
      case 'timestamp':
        return FormHelper.buildDate(
          label: label,
          controller: _controllers[key]!,
          isReq: isReq,
          isTime: type != 'date',
        );

      case 'gis':
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

      default:
        // Dropdown (Option or ID fields)
        if (type == "option" || (key.endsWith('_id') && key != 'zip_id')) {
          final cacheKey = key.replaceAll("_id", "");
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getOptions(cacheKey),
            builder: (context, snapshot) => FormHelper.buildDropdown(
              label: label,
              isReq: isReq,
              options: snapshot.data ?? [],
              currentValue: _currentFormData[key],
              onChanged: (val) => setState(() => _currentFormData[key] = val),
            ),
          );
        }
        
        // Standard Text Input
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
              final displayEntries = state.schema['properties'].entries
                  .where((e) => e.value['is_from_input'] == true).toList();

              int totalSteps = (displayEntries.length / _fieldsPerPage).ceil();
              int startIndex = _currentStep * _fieldsPerPage;
              int endIndex = min(startIndex + _fieldsPerPage, displayEntries.length);
              final currentFields = displayEntries.sublist(startIndex, endIndex);
              
              bool canProceed = _isCurrentStepValid(currentFields);

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
                            ...currentFields.map((e) => _buildDynamicControl(e.key, e.value)),
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
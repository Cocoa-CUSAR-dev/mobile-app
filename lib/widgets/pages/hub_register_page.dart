import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/upload_input.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';

class HubRegisterPage extends StatefulWidget {
  const HubRegisterPage({super.key});

  @override
  State<HubRegisterPage> createState() => _HubRegisterPageState();
}

class _HubRegisterPageState extends State<HubRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 3;

  final Map<String, dynamic> _currentFormData = {};
  
  // คอนโทรลเลอร์สำหรับ Text Fields
  final Map<String, TextEditingController> _controllers = {
    'hub_name': TextEditingController(),
    'found_date': TextEditingController(),
    'address_detail': TextEditingController(),
    'zip_code': TextEditingController(),
    'contact_name': TextEditingController(),
    'phone_number': TextEditingController(),
    'line': TextEditingController(),
    'facebook': TextEditingController(),
  };

  final Map<String, FileUploadController> _fileControllers = {
    'upload': FileUploadController(),
  };

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // --- Logic เช็คความครบถ้วนของข้อมูลเพื่อเปิดปุ่ม 'ถัดไป' ---
  bool _isCurrentStepValid() {
    final currentFields = _getFieldsForStep(_currentStep);
    
    for (var field in currentFields) {
      final key = field.key;
      final prop = field.value;
      final bool isRequired = prop['is_required'] ?? false;
      final String type = prop['type'] ?? 'string';

      if (!isRequired) continue;

      // กลุ่ม Text / Date
      if (['string', 'date'].contains(type) && !key.endsWith('_id')) {
        if (_controllers[key]?.text.trim().isEmpty ?? true) return false;
      } 
      // กลุ่ม Dropdown / GIS / File
      else {
        final value = _currentFormData[key];
        if (value == null) return false;
        if (value is List && value.isEmpty) return false;
      }
    }
    return true;
  }

  // แบ่ง Schema ตาม Step
  List<MapEntry<String, dynamic>> _getFieldsForStep(int step) {
    switch (step) {
      case 0: // ข้อมูลเบื้องต้น
        return [
          const MapEntry('hub_name', {'type': 'string', 'is_required': true}),
          const MapEntry('found_date', {'type': 'date', 'is_required': true}),
          const MapEntry('contact_name', {'type': 'string', 'is_required': true}),
          const MapEntry('phone_number', {'type': 'string', 'is_required': true}),
        ];
      case 1: // ที่อยู่
        return [
          const MapEntry('province_id', {'type': 'id', 'is_required': true}),
          const MapEntry('district_id', {'type': 'id', 'is_required': true}),
          const MapEntry('subdistrict_id', {'type': 'id', 'is_required': true}),
          const MapEntry('address_detail', {'type': 'string', 'is_required': true}),
          const MapEntry('zip_code', {'type': 'string', 'is_required': true}),
        ];
      case 2: // GIS และไฟล์
        return [
          const MapEntry('gis', {'type': 'gis', 'is_required': false}),
          const MapEntry('upload', {'type': 'file', 'is_required': false}),
        ];
      default:
        return [];
    }
  }

  // ดึงข้อมูล Dropdown (จังหวัด/อำเภอ/ตำบล)
  Future<List<Map<String, dynamic>>> _getOptions(String key, {String? filterId, String? filterKey}) async {
    if (filterKey != null && filterId == null) return [];
    try {
      final dynamicBloc = context.read<DynamicBloc>();
      final Map<String, String> params = {};
      if (filterKey != null && filterId != null) params[filterKey] = filterId;

      return await dynamicBloc.api.fetchConstants(
        key.replaceAll("_id", ""),
        queryParams: params,
      );
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final registerService = ServiceProvider(
        endpoint: '/hubs', 
        isRealApi: true, 
        storageKey: 'hubs'
      );

      final Map<String, dynamic> payload = _controllers.map((k, v) => MapEntry(k, v.text.trim()));
      payload.addAll(_currentFormData);

      await registerService.postData(payload);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลงทะเบียนหน่วยรวบรวม (Hub) สำเร็จ'))
        );
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoute.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = _isCurrentStepValid();

    return SimpleScaffold(
      title: '',
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildStepIndicator(_totalSteps),
                    const SizedBox(height: 32),
                    const Text(
                      'ข้อมูลหน่วยรวบรวม (Hub)',
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF794c46)
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCurrentStepFields(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(
              isLastStep: _currentStep == _totalSteps - 1, 
              canProceed: canProceed
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepFields() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            FormHelper.buildInput(
              label: 'ชื่อหน่วยรวบรวม (Hub)',
              controller: _controllers['hub_name']!,
              isReq: true,
              onChanged: () => setState(() {}),
            ),
            FormHelper.buildDate(
              label: 'วันที่ก่อตั้ง',
              controller: _controllers['found_date']!,
              isReq: true,
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildFilteredDropdown('province_id', 'จังหวัด', isReq: true, 
              onChanged: (val) => setState(() {
                _currentFormData['province_id'] = val;
                _currentFormData['district_id'] = null;
                _currentFormData['subdistrict_id'] = null;
              })
            ),
            _buildFilteredDropdown('district_id', 'อำเภอ', isReq: true, 
              filterId: _currentFormData['province_id']?.toString(),
              filterKey: 'province_id',
              onChanged: (val) => setState(() {
                _currentFormData['district_id'] = val;
                _currentFormData['subdistrict_id'] = null;
              })
            ),
            _buildFilteredDropdown('subdistrict_id', 'ตำบล', isReq: true,
              filterId: _currentFormData['district_id']?.toString(),
              filterKey: 'district_id',
              onChanged: (val) => setState(() => _currentFormData['subdistrict_id'] = val),
            ),
            // FormHelper.buildInput(
            //   label: 'ที่ตั้ง (เลขที่/ซอย/ถนน)',
            //   controller: _controllers['address_detail']!,
            //   isReq: true,
            //   onChanged: () => setState(() {}),
            // ),
            // FormHelper.buildInput(
            //   label: 'รหัสไปรษณีย์',
            //   controller: _controllers['zip_code']!,
            //   isReq: true,
            //   onChanged: () => setState(() {}),
            // ),
          ],
        );
      case 2:
        return Column(
          children: [
            FormHelper.buildGIS(
              label: 'ตำแหน่ง Hub',
              points: (_currentFormData['gis'] as List?)?.map((p) => LatLng(p['lat'], p['lng'])).toList() ?? [],
              areaM2: (_currentFormData['gis_area_m2'] ?? 0.0) as double,
              onChanged: (newData) => setState(() {
                _currentFormData['gis'] = newData.points.isEmpty 
                    ? null 
                    : newData.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
                _currentFormData['gis_area_m2'] = newData.areaM2;
              }),
            ),
            const SizedBox(height: 16),
            FormHelper.buildUpload(
              label: 'ภาพถ่ายหน่วยรวบรวม',
              controller: _fileControllers['upload']!,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFilteredDropdown(String key, String label, {bool isReq = false, String? filterId, String? filterKey, required Function(dynamic) onChanged}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('${key}_$filterId'), // สำคัญ: เพื่อให้สร้าง Widget ใหม่เมื่อ Filter เปลี่ยน
      future: _getOptions(key, filterId: filterId, filterKey: filterKey),
      builder: (context, snapshot) {
        return FormHelper.buildDropdown(
          label: label,
          isReq: isReq,
          isDropdown: true,
          options: snapshot.data ?? [],
          currentValue: _currentFormData[key],
          onChanged: (val) {
            onChanged(val);
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildStepIndicator(int totalSteps) {
    return Column(
      children: [
        Text("หน้า ${_currentStep + 1} จาก $totalSteps", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentStep >= i ? const Color(0xFF794c46) : Colors.grey.shade300,
              ),
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
                        _handleRegister();
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
          TextButton(
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              _currentStep > 0 ? 'ย้อนกลับ' : 'ยกเลิก', 
              style: const TextStyle(fontSize: 18, color: Colors.grey)
            ),
          ),
        ],
      ),
    );
  }
}
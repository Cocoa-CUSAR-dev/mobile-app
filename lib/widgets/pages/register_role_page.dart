import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';

class RegisterRolePage extends StatefulWidget {
  /// true = มาจาก flow "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing (สมัคร + เชื่อม
  /// บัญชี LINE ไปแล้วผ่าน LiffLinkPage) — ลงทะเบียนโปรไฟล์เสร็จให้ไปหน้า
  /// "สมัครสำเร็จ" (ปิด LIFF webview) แทนหน้า home ปกติ
  final bool fromLiff;

  const RegisterRolePage({super.key, this.fromLiff = false});

  @override
  State<RegisterRolePage> createState() => _RegisterRolePageState();
}

class _RegisterRolePageState extends State<RegisterRolePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  bool _isLoading = false;
  
  int _currentStep = 0;

  final Map<String, dynamic> _currentFormData = {};
  final Map<String, TextEditingController> _controllers = {
    'first_name': TextEditingController(),
    'last_name': TextEditingController(),
    'nickname': TextEditingController(),
    'birth_date': TextEditingController(),
    'id_card_number': TextEditingController(),
    'address_detail': TextEditingController(),
    'zip_code': TextEditingController(),
    'phone_number': TextEditingController(),
    'line': TextEditingController(),
    'email': TextEditingController(),
    'salary_income': TextEditingController(text: '0.00'),
    'family_member_count': TextEditingController(text: '0'),
    'agri_worker_count': TextEditingController(text: '0'),
    'agri_experience': TextEditingController(),
  };

  final Map<String, dynamic> _roleConfigs = {
    'farmer': {'endpoint': '/farmers', 'title': 'เกษตรกร'},
    'processor': {'endpoint': '/processors', 'title': 'ผู้แปรรูป'},
    'hub_collector': {'endpoint': '/hub_collectors', 'title': 'ผู้รวบรวม'},
  };

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ==========================================
  // 1. กำหนดชุดคำถามในแต่ละหน้า (ไม่เกิน 3 ข้อ)
  // ==========================================
  List<List<String>> _getStepKeys(String role) {
    if (role == 'farmer') {
      return [
        ['first_name', 'last_name', 'nickname'], // หน้า 1
        ['birth_date', 'phone_number', 'line'], // หน้า 2
        ['province_id', 'district_id', 'subdistrict_id'], // หน้า 3 (จังหวัด อำเภอ ตำบล รวมกัน)
        ['email', 'salary_income'], // หน้า 4
        ['family_member_count', 'agri_worker_count', 'agri_experience'], // หน้า 5
      ];
    } else if (role == 'processor') {
      return [
        ['first_name', 'last_name', 'nickname'],
        ['birth_date', 'id_card_number'],
        ['province_id', 'district_id', 'subdistrict_id'], // (จังหวัด อำเภอ ตำบล รวมกัน)
        ['zip_code', 'phone_number', 'line'],
        ['email'],
      ];
    } else {
      // hub_collector
      return [
        ['first_name', 'last_name', 'nickname'],
        ['birth_date', 'id_card_number', 'phone_number'],
        ['province_id', 'district_id', 'subdistrict_id'], // (จังหวัด อำเภอ ตำบล รวมกัน)
        ['line', 'email'],
      ];
    }
  }

  int get _totalSteps => _selectedRole == null ? 0 : _getStepKeys(_selectedRole!).length;

  // ==========================================
  // 2. กำหนดว่าฟิลด์ไหนจำเป็นต้องกรอก (Is Required)
  // ==========================================
  bool _isFieldRequired(String key, String role) {
    if (['first_name', 'last_name', 'nickname', 'birth_date'].contains(key)) return true;
    if (['province_id', 'district_id', 'subdistrict_id'].contains(key)) return true;
    
    if (role == 'farmer') {
      return ['zip_code', 'phone_number', 'salary_income', 'family_member_count', 'agri_worker_count'].contains(key);
    } else if (role == 'processor') {
      return ['id_card_number', 'address_detail'].contains(key);
    } else if (role == 'hub_collector') {
      return ['id_card_number'].contains(key);
    }
    return false;
  }

  // ==========================================
  // 3. Validation ของหน้าปัจจุบัน
  // ==========================================
  bool _isCurrentStepValid() {
    if (_selectedRole == null) return false;
    final stepKeys = _getStepKeys(_selectedRole!)[_currentStep];

    for (String key in stepKeys) {
      if (!_isFieldRequired(key, _selectedRole!)) continue;

      if (key.endsWith('_id')) { // กลุ่ม Dropdown
        if (_currentFormData[key] == null) return false;
      } else { // กลุ่ม Input
        if (_controllers[key]?.text.trim().isEmpty ?? true) return false;
      }
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> _getOptions(String key, {String? filterId, String? filterKey}) async {
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
      final String endpoint = _roleConfigs[_selectedRole!]['endpoint'];
      final registerService = ServiceProvider(endpoint: endpoint, isRealApi: true, storageKey: endpoint);

      final Map<String, dynamic> payload = _controllers.map((k, v) => MapEntry(k, v.text.trim()));
      payload.addAll(_currentFormData);

      if (_selectedRole == 'farmer') {
        payload['salary_income'] = double.tryParse(payload['salary_income'].toString()) ?? 0.0;
        payload['family_member_count'] = int.tryParse(payload['family_member_count'].toString()) ?? 0;
        payload['agri_worker_count'] = int.tryParse(payload['agri_worker_count'].toString()) ?? 0;
      }

      await registerService.postData(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ ลงทะเบียนสำเร็จ')));

        // ถ้ามาจากปุ่ม "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing (สมัคร + เชื่อม
        // บัญชี LINE ผ่าน LiffLinkPage มาแล้ว) ให้พาไปหน้า "สมัครสำเร็จ" (ปิด LIFF
        // webview) แทนหน้า home ปกติ
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.fromLiff ? AppRoute.liffRegisterSuccess : AppRoute.home,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      showBackButton: false,
      body: _selectedRole == null ? _buildRoleSelection() : _buildPaginatedForm(),
    );
  }

  Widget _buildRoleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          const Text('ลงทะเบียนเข้าใช้งาน', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('กรุณาเลือกประเภทสมาชิก', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 40),
          _roleCard('เกษตรกร', 'farmer', Icons.agriculture),
          const SizedBox(height: 16),
          _roleCard('ผู้รวบรวม (Hub)', 'hub_collector', Icons.local_shipping),
          const SizedBox(height: 16),
          _roleCard('ผู้แปรรูป', 'processor', Icons.factory),
        ],
      ),
    );
  }

  Widget _buildPaginatedForm() {
    return Form(
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
                  Text(
                    'ข้อมูล${_roleConfigs[_selectedRole!]['title']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF794c46)),
                  ),
                  const SizedBox(height: 24),
                  _buildCurrentStepFields(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(
            isLastStep: _currentStep == _totalSteps - 1, 
            canProceed: _isCurrentStepValid()
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. Render Field ตาม Key ที่ดึงมาจาก Step
  // ==========================================
  Widget _buildCurrentStepFields() {
    final stepKeys = _getStepKeys(_selectedRole!)[_currentStep];

    return Column(
      children: stepKeys.map((key) {
        bool isReq = _isFieldRequired(key, _selectedRole!);
        
        switch(key) {
          case 'first_name': return _input(key, 'ชื่อจริง', isReq);
          case 'last_name': return _input(key, 'นามสกุล', isReq);
          case 'nickname': return _input(key, 'ชื่อเล่น', isReq);
          case 'id_card_number': return _input(key, 'เลขบัตรประชาชน', isReq);
          case 'address_detail': return _input(key, 'ที่อยู่ (บ้านเลขที่/หมู่/ถนน)', isReq);
          case 'zip_code': return _input(key, 'รหัสไปรษณีย์', isReq);
          case 'phone_number': return _input(key, 'เบอร์โทรศัพท์', isReq);
          case 'line': return _input(key, 'Line ID', isReq);
          case 'email': return _input(key, 'อีเมล', isReq);
          case 'salary_income': return FormHelper.buildNumber(label: 'รายได้เฉลี่ยต่อเดือน (บาท)', controller: _controllers[key]!, isReq: isReq);
          case 'family_member_count': return FormHelper.buildNumber(label: 'จำนวนสมาชิกครอบครัว', controller: _controllers[key]!, isReq: isReq, isInt: true);
          case 'agri_worker_count': return FormHelper.buildNumber(label: 'จำนวนแรงงานเกษตร', controller: _controllers[key]!, isReq: isReq, isInt: true);
          case 'birth_date': return FormHelper.buildDate(label: 'วัน/เดือน/ปีเกิด', controller: _controllers[key]!, isReq: isReq);
          case 'agri_experience': return FormHelper.buildDate(label: 'วันที่เริ่มทำเกษตร', controller: _controllers[key]!, isReq: isReq);
          
          case 'province_id':
            return _buildFilteredDropdown('province_id', 'จังหวัด', isReq: isReq, 
              onChanged: (val) => setState(() {
                _currentFormData['province_id'] = val;
                _currentFormData['district_id'] = null; // รีเซ็ตอำเภอเมื่อเปลี่ยนจังหวัด
                _currentFormData['subdistrict_id'] = null;
              })
            );
          case 'district_id':
            return _buildFilteredDropdown('district_id', 'อำเภอ', isReq: isReq,
              filterId: _currentFormData['province_id']?.toString(),
              filterKey: 'province_id',
              onChanged: (val) => setState(() {
                _currentFormData['district_id'] = val;
                _currentFormData['subdistrict_id'] = null; // รีเซ็ตตำบลเมื่อเปลี่ยนอำเภอ
              })
            );
          case 'subdistrict_id':
            return _buildFilteredDropdown('subdistrict_id', 'ตำบล', isReq: isReq,
              filterId: _currentFormData['district_id']?.toString(),
              filterKey: 'district_id',
              onChanged: (val) => setState(() => _currentFormData['subdistrict_id'] = val),
            );
          default: 
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _input(String key, String label, bool isReq) {
    return FormHelper.buildInput(
      label: label, 
      controller: _controllers[key]!, 
      isReq: isReq, 
      onChanged: () => setState(() {}) // อัพเดตปุ่มถัดไปเมื่อพิมพ์
    );
  }

  Widget _buildFilteredDropdown(String key, String label, {bool isReq = false, String? filterId, String? filterKey, required Function(dynamic) onChanged}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('${key}_$filterId'),
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
                    if (isLastStep) {
                      _handleRegister();
                    } else {
                      setState(() => _currentStep++);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF794c46),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLastStep ? 'ยืนยันลงทะเบียน' : 'ถัดไป', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                setState(() => _selectedRole = null); // กลับไปเลือก Role ใหม่
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text(
              _currentStep > 0 ? 'ย้อนกลับ' : 'เปลี่ยนประเภทสมาชิก', 
              style: const TextStyle(fontSize: 18, color: Colors.black87)
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _roleCard(String title, String roleValue, IconData icon) {
    return InkWell(
      onTap: () => setState(() {
        _selectedRole = roleValue;
        _currentStep = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF794c46).withOpacity(0.1),
              child: Icon(icon, color: const Color(0xFF794c46)),
            ),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
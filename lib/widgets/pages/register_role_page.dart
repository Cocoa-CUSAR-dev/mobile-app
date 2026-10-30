import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/config/roles.dart';
import 'package:cocoa_supply/services/role_profile_payload.dart';
import 'package:cocoa_supply/services/role_registration.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_helper.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/widgets/components/app_snackbar.dart';
import 'package:cocoa_supply/services/dynamic_api_service.dart';

/// Pick one or more roles and fill in their profiles: right after sign-up,
/// or later from the profile sheet to add another role.
///
/// The shared fields (name, phone, address) are asked once for every picked
/// role; a role's own fields only when it is picked (see role_registration).
/// Each role is then saved with its own POST /me/roles/{role}; if one fails
/// the others stay saved and "ลองอีกครั้ง" retries only the failed ones.
class RegisterRolePage extends StatefulWidget {
  /// true = มาจาก flow "ยังไม่มีบัญชีผู้ใช้" บนหน้า LIFF landing (สมัคร + เชื่อม
  /// บัญชี LINE ไปแล้วผ่าน LiffLinkPage) — ลงทะเบียนโปรไฟล์เสร็จให้ไปหน้า
  /// "สมัครสำเร็จ" (ปิด LIFF webview) แทนหน้า home ปกติ
  final bool fromLiff;

  /// Roles the person already holds. Non-empty means "add a role" from the
  /// profile sheet: those roles can't be picked again, and Back leaves.
  final Set<String> ownedRoles;

  /// Answers to start with (registrationPrefill of the person's profiles).
  final Map<String, String> prefill;

  const RegisterRolePage({
    super.key,
    this.fromLiff = false,
    this.ownedRoles = const {},
    this.prefill = const {},
  });

  @override
  State<RegisterRolePage> createState() => _RegisterRolePageState();
}

class _RegisterRolePageState extends State<RegisterRolePage> {
  final _formKey = GlobalKey<FormState>();
  final Set<String> _pickedRoles = {};
  bool _choosingRoles = true;
  bool _isLoading = false;

  int _currentStep = 0;

  // Per role, once submitting started: saved, or the message it was refused with.
  final Set<String> _savedRoles = {};
  final Map<String, String> _failedRoles = {};

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
    'salary_income': TextEditingController(text: '0.00'),
    'family_member_count': TextEditingController(text: '0'),
    'agri_worker_count': TextEditingController(text: '0'),
    'agri_experience': TextEditingController(),
  };

  bool get _addingRole => widget.ownedRoles.isNotEmpty;

  /// Picked roles in the app's usual order.
  List<String> get _rolesInOrder => selfServiceRoles.where(_pickedRoles.contains).toList();

  List<List<String>> get _steps => registrationSteps(_pickedRoles);

  int get _totalSteps => _steps.length;

  @override
  void initState() {
    super.initState();
    widget.prefill.forEach((key, value) {
      if (key.endsWith('_id')) {
        _currentFormData[key] = value;
      } else {
        _controllers[key]?.text = value;
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  bool _isRequired(String key) => isRegistrationFieldRequired(key, _pickedRoles);

  // ==========================================
  // Validation ของหน้าปัจจุบัน
  // ==========================================
  bool _isCurrentStepValid() {
    if (_pickedRoles.isEmpty) return false;
    for (String key in _steps[_currentStep]) {
      if (!_isRequired(key)) continue;

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

  Map<String, dynamic> _answers() {
    final Map<String, dynamic> form = _controllers.map((k, v) => MapEntry(k, v.text.trim()));
    form.addAll(_currentFormData);
    form['salary_income'] = double.tryParse(form['salary_income'].toString()) ?? 0.0;
    form['family_member_count'] = int.tryParse(form['family_member_count'].toString()) ?? 0;
    form['agri_worker_count'] = int.tryParse(form['agri_worker_count'].toString()) ?? 0;
    return form;
  }

  /// Save every picked role not saved yet, one request each. Each answer
  /// carries a new token pair (kept by postData), so the last one holds
  /// every role.
  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final form = _answers();
    for (final role in _rolesInOrder) {
      if (_savedRoles.contains(role)) continue;
      final endpoint = ApiEndpoints.meRole(role);
      final service = ServiceProvider(endpoint: endpoint, isRealApi: true, storageKey: endpoint);
      try {
        // The backend takes exactly the fields of the role's profile, so the
        // form's other fields and its blank answers are left out.
        await service.postData(roleProfilePayload(role, form));
        _savedRoles.add(role);
        _failedRoles.remove(role);
      } on ServerRejection catch (e) {
        if (e.statusCode == 409) {
          // Already holds it (a double tap, or another device): that's done.
          _savedRoles.add(role);
          _failedRoles.remove(role);
        } else {
          _failedRoles[role] = e.message;
        }
      } catch (_) {
        _failedRoles[role] = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_failedRoles.isNotEmpty) {
      AppSnackBar.show(context, 'บันทึกไม่สำเร็จบางบทบาท กรุณาลองอีกครั้ง', type: AppSnackBarType.error);
      return;
    }
    final names = _rolesInOrder.map(roleLabel).join(', ');
    AppSnackBar.show(
      context,
      _addingRole ? 'เพิ่มบทบาท$namesเรียบร้อย' : 'ลงทะเบียนสำเร็จ',
      type: AppSnackBarType.success,
    );
    // ถ้ามาจาก LiffLinkPage (login/link ผ่านแล้วแต่ยังไม่มีโปรไฟล์ตอนนั้น)
    // ให้พาไปหน้า "เชื่อมบัญชีสำเร็จ" (ปิด LIFF webview) แทนหน้า home ปกติ
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.fromLiff ? AppRoute.liffLoginSuccess : AppRoute.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      title: '',
      showBackButton: _addingRole,
      body: _choosingRoles ? _buildRoleSelection() : _buildPaginatedForm(),
    );
  }

  Widget _buildRoleSelection() {
    final roleCards = <Widget>[];
    for (final role in selfServiceRoles) {
      if (roleCards.isNotEmpty) roleCards.add(const SizedBox(height: 16));
      roleCards.add(_roleCard(role));
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: _addingRole ? 24 : 80),
                Text(
                  _addingRole ? 'เพิ่มบทบาท' : 'ลงทะเบียนเข้าใช้งาน',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'คุณทำอะไรบ้าง? เลือกได้มากกว่า 1 บทบาท',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 40),
                ...roleCards,
                if (!_addingRole) ...[
                  const SizedBox(height: 24),
                  Text(
                    'เพิ่มบทบาทภายหลังได้ที่หน้าโปรไฟล์',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _pickedRoles.isEmpty
                ? null
                : () => setState(() {
                      _choosingRoles = false;
                      _currentStep = 0;
                    }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('ถัดไป', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginatedForm() {
    final isLastStep = _currentStep == _totalSteps - 1;
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
                    _stepTitle(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  _buildCurrentStepFields(),
                  if (isLastStep && (_savedRoles.isNotEmpty || _failedRoles.isNotEmpty)) _buildSaveResults(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(isLastStep: isLastStep, canProceed: _isCurrentStepValid()),
        ],
      ),
    );
  }

  /// Shared pages are "ข้อมูลส่วนตัว"; a page of one role's own fields is
  /// named after that role.
  String _stepTitle() {
    final ownFields = {'salary_income', 'family_member_count', 'agri_worker_count', 'agri_experience'};
    final isFarmerPage = _steps[_currentStep].every(ownFields.contains);
    return isFarmerPage ? 'ข้อมูล${roleLabel('farmer')}' : 'ข้อมูลส่วนตัว';
  }

  /// After a submit that partly failed: which roles were saved, which not.
  Widget _buildSaveResults() {
    return Column(
      children: _rolesInOrder.map((role) {
        final failed = _failedRoles[role];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            failed == null ? Icons.check_circle : Icons.error,
            color: failed == null ? Colors.green : Colors.red,
          ),
          title: Text(roleLabel(role)),
          subtitle: Text(failed ?? 'บันทึกแล้ว'),
        );
      }).toList(),
    );
  }

  // ==========================================
  // Render Field ตาม Key ที่ดึงมาจาก Step
  // ==========================================
  Widget _buildCurrentStepFields() {
    return Column(
      children: _steps[_currentStep].map((key) {
        bool isReq = _isRequired(key);

        switch(key) {
          case 'first_name': return _input(key, 'ชื่อจริง', isReq);
          case 'last_name': return _input(key, 'นามสกุล', isReq);
          case 'nickname': return _input(key, 'ชื่อเล่น', isReq);
          case 'id_card_number': return _input(key, 'เลขบัตรประชาชน', isReq);
          case 'address_detail': return _input(key, 'ที่อยู่ (บ้านเลขที่/หมู่/ถนน)', isReq);
          case 'zip_code': return _input(key, 'รหัสไปรษณีย์', isReq);
          case 'phone_number': return _phoneInput(key, isReq);
          case 'line': return _input(key, 'Line ID', isReq);
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
            return _buildFilteredDropdown(
              'district_id',
              DynamicApiService.isBangkokProvinceId(_currentFormData['province_id']?.toString())
                  ? 'เขต'
                  : 'อำเภอ',
              isReq: isReq,
              filterId: _currentFormData['province_id']?.toString(),
              filterKey: 'province_id',
              onChanged: (val) => setState(() {
                _currentFormData['district_id'] = val;
                _currentFormData['subdistrict_id'] = null; // รีเซ็ตตำบลเมื่อเปลี่ยนอำเภอ
              })
            );
          case 'subdistrict_id':
            return _buildFilteredDropdown(
              'subdistrict_id',
              DynamicApiService.isBangkokProvinceId(_currentFormData['province_id']?.toString())
                  ? 'แขวง'
                  : 'ตำบล',
              isReq: isReq,
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

  Widget _phoneInput(String key, bool isReq) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormInput(
        label: 'เบอร์โทรศัพท์',
        hintText: 'เช่น 08XXXXXXXX',
        controller: _controllers[key]!,
        isRequired: isReq,
        keyboardType: TextInputType.phone,
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (!isReq) return null;
          if (v == null || v.isEmpty) return 'กรุณาระบุเบอร์โทรศัพท์';
          if (!RegExp(r'^0[0-9]{9}$').hasMatch(v)) {
            return 'เบอร์โทรต้องเป็นตัวเลข 10 หลัก (เช่น 08XXXXXXXX)';
          }
          return null;
        },
      ),
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
    final submitLabel = _failedRoles.isNotEmpty ? 'ลองอีกครั้ง' : 'ยืนยันลงทะเบียน';
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
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLastStep ? submitLabel : 'ถัดไป', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            // Once a role is saved, changing the picked roles would leave it
            // half-done; the remaining ones can only be retried.
            onPressed: _currentStep == 0 && _savedRoles.isNotEmpty
                ? null
                : () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    } else {
                      setState(() => _choosingRoles = true); // กลับไปเลือกบทบาทใหม่
                    }
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text(
              _currentStep > 0 ? 'ย้อนกลับ' : 'เลือกบทบาทใหม่',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87)
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, IconData> _roleIcons = {
    'farmer': Icons.agriculture,
    'hub_collector': Icons.local_shipping,
    'processor': Icons.factory,
  };

  Widget _roleCard(String role) {
    final owned = widget.ownedRoles.contains(role);
    final picked = _pickedRoles.contains(role);
    final title = role == 'hub_collector' ? '${roleLabel(role)} (Hub)' : roleLabel(role);
    return InkWell(
      onTap: owned
          ? null
          : () => setState(() {
                if (!_pickedRoles.remove(role)) _pickedRoles.add(role);
              }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: owned ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? AppColors.primary : Colors.grey.shade200,
            width: picked ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: owned ? 0.05 : 0.1),
              child: Icon(_roleIcons[role], color: owned ? Colors.grey : AppColors.primary),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: owned ? Colors.grey : null),
            ),
            const Spacer(),
            if (owned)
              Text('มีแล้ว', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))
            else
              Icon(
                picked ? Icons.check_box : Icons.check_box_outline_blank,
                color: picked ? AppColors.primary : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}

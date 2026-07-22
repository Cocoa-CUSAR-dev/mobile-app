import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/widgets/components/date_input.dart';
import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:cocoa_supply/widgets/components/gis_input.dart';
import 'package:cocoa_supply/widgets/components/upload_input.dart';

class ProcessingStationRegisterPage extends StatefulWidget {
  const ProcessingStationRegisterPage({super.key});

  @override
  State<ProcessingStationRegisterPage> createState() => _ProcessingStationRegisterPageState();
}

class _ProcessingStationRegisterPageState extends State<ProcessingStationRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  final Map<String, List<Map<String, dynamic>>> _dropdownOptions = {};
  late Map<String, dynamic> _currentFormData;

  final Map<String, TextEditingController> _controllers = {
    'processing_station_name': TextEditingController(),
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
  void initState() {
    super.initState();
    _currentFormData = {
      'province_id': null,
      'district_id': null,
      'subdistrict_id': null,
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getOptions(String key) async {
    if (_dropdownOptions.containsKey(key)) return _dropdownOptions[key]!;
    try {
      final dynamicBloc = context.read<DynamicBloc>();
      // กรณีพิเศษสำหรับการโหลดที่อยู่แบบสัมพันธ์กัน (Cascading)
      // หากต้องการทำ Filter รายจังหวัด/อำเภอ สามารถเพิ่ม Logic ตรงนี้ได้
      var data = await dynamicBloc.api.fetchConstants(key.replaceAll("_id", ""));
      if (!mounted) return [];
      setState(() => _dropdownOptions[key] = data);
      return data;
    } catch (e) {
      debugPrint('Error loading options for $key: $e');
      return [];
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final registerService = ServiceProvider<dynamic>(
        endpoint: '/processing_stations',
        isRealApi: true,
        storageKey: '/processing_stations',
      );

      final Map<String, dynamic> payload = _controllers.map(
        (key, controller) => MapEntry(key, controller.text.trim()),
      );

      payload.addAll(_currentFormData);

      // ส่งข้อมูลไปยัง API
      await registerService.postData(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลงทะเบียนสถานีแปรรูปสำเร็จ'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ข้อผิดพลาด: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // รายการคำถามแยกตาม Schema
    final List<Widget> allFields = [
      _input('processing_station_name', 'ชื่อสถานีแปรรูป', isReq: true),
      _date('found_date', 'วันที่ก่อตั้ง'),
      _input('address_detail', 'ที่ตั้ง/บ้านเลขที่'),
      _dropdown('province_id', 'จังหวัด', isReq: true),
      _dropdown('district_id', 'อำเภอ', isReq: true),
      _dropdown('subdistrict_id', 'ตำบล', isReq: true),
      _input('zip_code', 'รหัสไปรษณีย์'),
      _input('contact_name', 'ชื่อผู้ติดต่อ'),
      _input('phone_number', 'เบอร์โทรศัพท์'),
      _input('line', 'Line ID'),
      _input('facebook', 'Facebook'),
      _gis('gis', 'ตำแหน่งปัจจุบัน (GIS)'),
      _upload('upload', 'แนบภาพประกอบ'),
    ];

    int totalSteps = allFields.length;
    bool isLastStep = (_currentStep + 1) >= totalSteps;

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
                    _buildStepIndicator(totalSteps),
                    const SizedBox(height: 32),
                    const Text(
                      'ข้อมูลสถานีแปรรูป',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF794c46)),
                    ),
                    const SizedBox(height: 24),
                    allFields[_currentStep],
                  ],
                ),
              ),
            ),
            _buildBottomButtons(isLastStep, totalSteps),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE COMPONENTS (เหมือนเดิม ปรับแต่งตาม Schema ใหม่) ---

  Widget _input(String key, String label, {bool isReq = false}) {
    return FormInput(
      label: label,
      controller: _controllers[key]!,
      isRequired: isReq,
      hintText: 'กรอก$label',
      validator: (value) => (isReq && (value == null || value.isEmpty)) ? 'กรุณากรอกข้อมูล' : null,
    );
  }

  Widget _date(String key, String label, {bool isReq = false}) {
    return DateInput(label: label, controller: _controllers[key]!, isRequired: isReq);
  }

  Widget _dropdown(String key, String label, {bool isReq = false}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getOptions(key),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return DropdownInput<Map<String, dynamic>, dynamic>(
          label: label,
          isRequired: isReq,
          items: items,
          value: _currentFormData[key],
          onChanged: (val) {
            setState(() => _currentFormData[key] = val);
            // ถ้ามีการเปลี่ยนจังหวัด ให้ล้างค่าอำเภอ/ตำบล (ถ้ามี Logic กรอง)
            if (key == 'province_id') {
              _dropdownOptions.remove('district_id');
              _dropdownOptions.remove('subdistrict_id');
            }
          },
          itemLabelBuilder: (opt) {
            final vals = opt.values.toList();
            return vals.length > 1 ? vals[1].toString() : '';
          },

          itemValueBuilder: (opt) {
            final vals = opt.values.toList();
            return vals.isNotEmpty ? vals.first : null;
          },
        );
      },
    );
  }

  Widget _gis(String key, String label) {
    return GISInput(
      label: label,
      data: PolygonData(
        points: (_currentFormData[key] as List?)?.map((p) => LatLng(p['lat'], p['lng'])).toList() ?? [],
        areaM2: 0.0,
      ),
      onChanged: (newData) {
        setState(() {
          _currentFormData[key] = newData.points.isEmpty 
            ? null 
            : newData.points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
        });
      },
      isRequired: false,
    );
  }

  Widget _upload(String key, String label) {
    return UploadInput(label: label, controller: _fileControllers[key]!);
  }

  // --- UI HELPERS ---

  Widget _buildStepIndicator(int totalSteps) {
    return Column(
      children: [
        Text("ขั้นตอนที่ ${_currentStep + 1} จาก $totalSteps", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentStep + 1) / totalSteps,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF794c46),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isLastStep, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      if (isLastStep) {
                        _handleRegister();
                      } else {
                        setState(() => _currentStep++);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF794c46),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isLastStep ? 'ยืนยันลงทะเบียนสถานี' : 'ต่อไป', style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _currentStep > 0 ? setState(() => _currentStep--) : Navigator.pop(context),
            child: Text(_currentStep > 0 ? 'ย้อนกลับ' : 'ยกเลิก', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
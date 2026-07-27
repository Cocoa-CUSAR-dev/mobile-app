import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:cocoa_supply/bloc/dynamic/dynamic.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/widgets/components/date_input.dart';
import 'package:cocoa_supply/widgets/components/number_input.dart';
import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:cocoa_supply/widgets/components/gis_input.dart';
import 'package:cocoa_supply/widgets/components/upload_input.dart';
import 'package:cocoa_supply/widgets/components/checkbox_input.dart';

class PlotRegisterPage extends StatefulWidget {
  final String farmId; // รับ farmId เข้ามาโดยตรง

  const PlotRegisterPage({super.key, required this.farmId});

  @override
  State<PlotRegisterPage> createState() => _PlotRegisterPageState();
}

class _PlotRegisterPageState extends State<PlotRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  final Map<String, List<Map<String, dynamic>>> _dropdownOptions = {};
  late Map<String, dynamic> _currentFormData;

  final Map<String, TextEditingController> _controllers = {
    'plot_name': TextEditingController(),
    'land_ownership': TextEditingController(),
    'cocoa_planted_area': TextEditingController(text: '0.00'),
    'found_date': TextEditingController(),
  };

  final Map<String, FileUploadController> _fileControllers = {
    'upload': FileUploadController(),
  };

  @override
  void initState() {
    super.initState();
    // กำหนด farm_id ลงในข้อมูลฟอร์มทันที
    _currentFormData = {
      'farm_id': widget.farmId,
      'has_chemical_use': false, // ค่าเริ่มต้น
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
        endpoint: '/plots',
        isRealApi: true,
        storageKey: '/plots',
      );

      final Map<String, dynamic> payload = _controllers.map(
        (key, controller) => MapEntry(key, controller.text.trim()),
      );

      payload.addAll(_currentFormData);

      // แปลงค่า Number
      payload['cocoa_planted_area'] =
          double.tryParse(payload['cocoa_planted_area'].toString()) ?? 0.0;

      await registerService.postData(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ลงทะเบียนแปลงปลูกสำเร็จ'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // รายการคำถาม (ข้าม farm_id เพราะเซตค่าไว้แล้ว)
    final List<Widget> allFields = [
      _input('plot_name', 'ชื่อแปลง', isReq: true),
      _input('land_ownership', 'ชื่อเจ้าของกรรมสิทธิ์', isReq: true),
      _number(
        'cocoa_planted_area',
        'พื้นที่ปลูกโกโก้จริงโดยคร่าว (ไร่)',
        isReq: true,
      ),
      _boolean('has_chemical_use', 'มีการใช้สารเคมีหรือไม่'),
      _dropdown('land_type_id', 'ลักษณะพื้นที่ (หากระบุไม่ได้ไม่ต้องเลือก)'),
      _dropdown('soil_type_id', 'ลักษณะดิน (หากระบุไม่ได้ไม่ต้องเลือก)'),
      _dropdown(
        'water_source_id',
        'แหล่งน้ำภายในแปลง  (หากระบุไม่ได้ไม่ต้องเลือก)',
      ),
      _dropdown('watering_system_id', 'ระบบน้ำที่ใช้ภายในแปลง'),
      _date(
        'found_date',
        'วันที่เริ่มปลูก (หากระบุไม่ได้ให้กรอกเป็นวันที่ 1 มกราคมของปีที่ท่านปลูก)',
        isReq: true,
      ),
      _gis('gis', 'ตำแหน่งแปลงปลูก (GIS)'),
      _upload('upload', 'แนบภาพประกอบแปลง'),
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
                      'ข้อมูลแปลงปลูกโกโก้',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF794c46),
                      ),
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

  // --- REUSABLE COMPONENTS ---

  Widget _input(String key, String label, {bool isReq = false}) {
    return FormInput(
      label: label,
      controller: _controllers[key]!,
      isRequired: isReq,
      hintText: 'กรอก$label',
      validator: (value) {
        if (isReq && (value == null || value.isEmpty)) {
          return 'กรุณากรอกข้อมูล'; // ข้อความที่จะปรากฏเป็นสีแดง
        }
        return null;
      },
    );
  }

  Widget _number(String key, String label, {bool isReq = false}) {
    return NumberInput(
      label: label,
      controller: _controllers[key]!,
      isRequired: isReq,
      interval: 1,
    );
  }

  Widget _date(String key, String label, {bool isReq = false}) {
    return DateInput(
      label: label,
      controller: _controllers[key]!,
      isRequired: isReq,
    );
  }

  Widget _boolean(String key, String label) {
    return CheckboxInput(
      label: label,
      initialValue: _currentFormData[key] ?? false,
      onChanged: (val) => setState(() => _currentFormData[key] = val),
    );
  }

  Widget _dropdown(String key, String label, {bool isReq = false}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getOptions(key.replaceAll("_id", "")),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return DropdownInput<Map<String, dynamic>, dynamic>(
          label: label,
          isRequired: isReq,
          items: items,
          value: _currentFormData[key],
          onChanged: (val) => setState(() => _currentFormData[key] = val),
          itemLabelBuilder: (opt) => opt.entries
              .firstWhere(
                (e) => !e.key.endsWith('_id'),
                orElse: () => opt.entries.first,
              )
              .value
              .toString(),
          itemValueBuilder: (opt) => opt.entries
              .firstWhere(
                (e) => e.key.endsWith('_id'),
                orElse: () => opt.entries.first,
              )
              .value,
        );
      },
    );
  }

  Widget _gis(String key, String label) {
    return GISInput(
      label: label,
      data: PolygonData(
        points:
            (_currentFormData[key] as List?)
                ?.map((p) => LatLng(p['lat'], p['lng']))
                .toList() ??
            [],
        areaM2: (_currentFormData['${key}_area_m2'] ?? 0.0) as double,
      ),
      onChanged: (newData) {
        setState(() {
          _currentFormData[key] = newData.points.isEmpty
              ? null
              : newData.points
                    .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                    .toList();
          _currentFormData['${key}_area_m2'] = newData.areaM2;
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
        Text(
          "หน้า ${_currentStep + 1} จาก $totalSteps",
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalSteps,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == i ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentStep == i
                    ? const Color(0xFF794c46)
                    : Colors.grey.shade300,
              ),
            ),
          ),
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("กรุณากรอกข้อมูลให้ครบถ้วน"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF794c46),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isLastStep ? 'บันทึกข้อมูลแปลง' : 'ต่อไป',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep > 0 ? 'ย้อนกลับ' : 'ยกเลิก',
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:cocoa_supply/widgets/components/form_input.dart';
import 'package:cocoa_supply/widgets/components/number_input.dart';
import 'package:cocoa_supply/widgets/components/date_input.dart';
import 'package:cocoa_supply/widgets/components/date_time_input.dart';
import 'package:cocoa_supply/widgets/components/dropdown_input.dart';
import 'package:cocoa_supply/widgets/components/gis_input.dart';
import 'package:cocoa_supply/widgets/components/upload_input.dart';
import 'package:cocoa_supply/widgets/components/checkbox_input.dart';

class FormHelper {
  static Widget buildInput({
    required String label,
    required TextEditingController controller,
    bool isReq = false,
    bool isTextArea = false,
    String? hintText,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormInput(
        label: label,
        controller: controller,
        isRequired: isReq,
        isTextArea: isTextArea,
        hintText: hintText,
        onChanged: (_) => onChanged?.call(),
        validator: (v) => (isReq && (v == null || v.isEmpty)) ? 'กรุณากรอก$label' : null,
      ),
    );
  }

  static Widget buildNumber({
    required String label,
    required TextEditingController controller,
    bool isReq = false,
    bool isInt = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NumberInput(
        label: label,
        controller: controller,
        isRequired: isReq,
        isInt: isInt,
      ),
    );
  }

  static Widget buildDate({
    required String label,
    required TextEditingController controller,
    bool isReq = false,
    bool isTime = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isTime
          ? DateTimeInput(label: label, controller: controller, isRequired: isReq)
          : DateInput(label: label, controller: controller, isRequired: isReq),
    );
  }

  static Widget buildDropdown({
    required String label,
    required List<Map<String, dynamic>> options,
    required dynamic currentValue,
    required Function(dynamic) onChanged,
    bool isReq = false,
    bool isDropdown = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownInput<Map<String, dynamic>, dynamic>(
        label: label,
        isRequired: isReq,
        isDropdown: isDropdown,
        items: options,
        value: currentValue,
        onChanged: onChanged,
        itemLabelBuilder: (opt) => opt.values.length > 1 ? opt.values.toList()[1].toString() : '',
        itemValueBuilder: (opt) => opt.values.isNotEmpty ? opt.values.first : null,
      ),
    );
  }

  static Widget buildGIS({
    required String label,
    required List<LatLng> points,
    required double areaM2,
    required Function(PolygonData) onChanged,
    bool isReq = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GISInput(
        label: label,
        isRequired: isReq,
        data: PolygonData(points: points, areaM2: areaM2),
        onChanged: onChanged,
      ),
    );
  }

  static Widget buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CheckboxInput(
        label: label,
        initialValue: value,
        onChanged: onChanged,
      ),
    );
  }

  static Widget buildUpload({
    required String label,
    required FileUploadController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UploadInput(
        label: label, 
        controller: controller,
      ),
    );
  }
}
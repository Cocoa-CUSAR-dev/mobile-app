import 'package:cocoa_supply/services/service_provider.dart';

class DynamicApiService {
  /// ดึงข้อมูลตาม table
  Future<List<Map<String, dynamic>>> fetchData(String tableName,
      {Map<String, dynamic>? queryParams}) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: '${tableName}_data',
      endpoint: '/$tableName',
    );

    return provider.fetchData(
      (json) => Map<String, dynamic>.from(json),
      queryParams: queryParams,
    );
  }

  /// บันทึกข้อมูล (POST / PATCH)
  Future<void> submitData(
    String tableName,
    Map<String, dynamic> data, {
    bool isEdit = false,
  }) async {
    final provider = ServiceProvider<Map<String, dynamic>>(
      storageKey: '${tableName}_data',
      endpoint: '/$tableName',
    );

    try {
      if (isEdit) {
        await provider.putData(data); // id มักเป็น value ตัวแรก ของ json
      } else {
        await provider.postData(data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchConstants(String key,
      {Map<String, dynamic>? queryParams}) async {
    // 1. สร้าง Instance ของ ServiceProvider สำหรับ Constants
    // ปรับ endpoint ให้เป็นแบบ dynamic ตาม key ที่ส่งมา
    final service = ServiceProvider<Map<String, dynamic>>(
      storageKey: 'constants_$key', // เก็บลง storage แยกตามประเภท
      endpoint: '/constants/$key', 
      isRealApi: true, // เปิดใช้งาน API จริง
    );

    try {
      // 2. เรียก fetchData โดยส่ง 'creator' เป็นฟังก์ชันที่ return map ตรงๆß
      // เนื่องจากเราต้องการ data ดิบมาใช้งานใน UI แบบ dynamic
      final List<Map<String, dynamic>> results = await service.fetchData(
        (json) => json, // creator: รับ json map มาแล้วคืนค่าออกไปเลย
        queryParams: queryParams,
      );
      print(key);
      print(results);
      return results;
    } catch (e) {
      print('Error fetching constants for $key: $e');
      
      // 3. Fallback: กรณี Error หรือ Server ล่ม 
      // คุณสามารถเลือกได้ว่าจะคืนค่าว่าง [] หรือจะเอา Mock Data เดิมมาใส่ไว้ที่นี่
      return []; 
    }
  }
  /// ดึง constant table
  // Future<List<Map<String, dynamic>>> fetchConstants(String key) async {
  //   final constantTable =
  //       "${key.replaceAll('_id', '')}_constant";

  //   final provider = ServiceProvider<Map<String, dynamic>>(
  //     storageKey: '${constantTable}_data',
  //     endpoint: '/$constantTable',
  //   );

  //   try {
  //     return provider.fetchData(
  //       (json) => Map<String, dynamic>.from(json),
  //     );
  //   } catch (_) {
  //     return [];
  //   }
  // }
//   Future<List<Map<String, dynamic>>> fetchConstants(String key) async {
//   try {
//     switch (key) {

//       case 'province_id':
//         return [
//           {
//             'province_id': '86',
//             'province_name_th': 'ชุมพร',
//             'province_name_en': 'Chumphon',
//             'description': 'แหล่งปลูกหลักทางภาคใต้'
//           },
//           {
//             'province_id': '50',
//             'province_name_th': 'เชียงใหม่',
//             'province_name_en': 'Chiang Mai',
//             'description': 'แหล่งปลูกและแปรรูปภาคเหนือ'
//           },
//           {
//             'province_id': '55',
//             'province_name_th': 'น่าน',
//             'province_name_en': 'Nan',
//             'description': 'พื้นที่ส่งเสริมการปลูกโกโก้คุณภาพสูง'
//           },
//           {
//             'province_id': '21',
//             'province_name_th': 'ระยอง',
//             'province_name_en': 'Rayong',
//             'description': 'พื้นที่ปลูกภาคตะวันออก'
//           },
//         ];

//       case 'subdistrict_id':
//         return [
//           {
//             'province_id': '86',
//             'subdistrict_id': '8601',
//             'subdistrict_name_th': 'ในเมือง',
//             'subdistrict_name_en': 'Nai Mueang'
//           },
//           {
//             'province_id': '50',
//             'subdistrict_id': '5001',
//             'subdistrict_name_th': 'ศรีภูมิ',
//             'subdistrict_name_en': 'Si Phum'
//           },
//         ];

//       case 'district_id':
//         return [
//           {
//             'district_id': '860101',
//             'district_name_th': 'เมืองชุมพร',
//             'district_name_en': 'Mueang Chumphon',
//             'subdistrict_id': '8601'
//           },
//           {
//             'district_id': '500101',
//             'district_name_th': 'เมืองเชียงใหม่',
//             'district_name_en': 'Mueang Chiang Mai',
//             'subdistrict_id': '5001'
//           },
//         ];

//       case 'breed_id':
//         return [
//           {'breed_id': 'CR', 'breed_name_th': 'คริโอโล', 'breed_name_en': 'Criollo', 'parent_age_min_years': 5},
//           {'breed_id': 'FO', 'breed_name_th': 'ฟอรัสเทอร์โร', 'breed_name_en': 'Forastero', 'parent_age_min_years': 5},
//           {'breed_id': 'TR', 'breed_name_th': 'ทรินิทาริโอ', 'breed_name_en': 'Trinitario', 'parent_age_min_years': 5},
//           {'breed_id': 'CH1', 'breed_name_th': 'พันธุ์ชุมพร 1', 'breed_name_en': 'Chumphon 1', 'parent_age_min_years': 5},
//           {'breed_id': 'IM1', 'breed_name_th': 'พันธุ์ IM1', 'breed_name_en': 'IM1', 'parent_age_min_years': 5},
//           {'breed_id': 'IC95', 'breed_name_th': 'พันธุ์ ICS95', 'breed_name_en': 'ICS95', 'parent_age_min_years': 5},
//           {'breed_id': 'PA7NA32', 'breed_name_th': 'พันธุ์ Pa7xNa32', 'breed_name_en': 'Pa7xNa32', 'parent_age_min_years': 5},
//           {'breed_id': 'OTHER', 'breed_name_th': 'อื่นๆ โปรดระบุที่หมายเหตุ', 'breed_name_en': 'Other', 'parent_age_min_years': 5},
//         ];

//       case 'role_id':
//         return [
//           {'role_id': 'ADMIN', 'role_name': 'ผู้ดูแลระบบ'},
//           {'role_id': 'FARMER', 'role_name': 'เกษตรกร'},
//           {'role_id': 'COLLECTOR', 'role_name': 'จุดรับซื้อ/สหกรณ์'},
//           {'role_id': 'PROCESSOR', 'role_name': 'โรงแปรรูป/โรงหมัก'},
//           {'role_id': 'OTHER', 'role_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'}
//         ];

//       case 'air_exposure_type_id':
//         return [
//           {'air_exposure_type_id': 'AER', 'air_exposure_type_name': 'แบบใช้ออกซิเจน (เปิดกว้าง)'},
//           {'air_exposure_type_id': 'ANA', 'air_exposure_type_name': 'แบบไม่ใช้ออกซิเจน (ปิดทึบ)'},
//           {'air_exposure_type_id': 'OTHER', 'air_exposure_type_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'cocoa_bean_grade_id':
//         return [
//           {'cocoa_bean_grade_id': 'GRADE_1', 'cocoa_bean_grade_name': 'ชั้นพิเศษ (Grade 1)'},
//           {'cocoa_bean_grade_id': 'GRADE_2', 'cocoa_bean_grade_name': 'ชั้น 1 (Grade 2)'},
//           {'cocoa_bean_grade_id': 'GRADE_3', 'cocoa_bean_grade_name': 'ชั้น 2 (Grade 3)'},
//           {'cocoa_bean_grade_id': 'UNDER', 'cocoa_bean_grade_name': 'ต่ำกว่ามาตรฐาน'},
//         ];

//       case 'grade_id':
//         return [
//           {'grade_id': 'BLACK_SPOT', 'grade_name': 'เกิดราดำ (ตกเกรด)'},
//           {'grade_id': 'DISCARD', 'grade_name': 'ทิ้ง (ตกเกรด)'},
//           {'grade_id': 'SMALL', 'grade_name': 'ผลมีขนาดเล็ก'},
//           {'grade_id': 'LARGE', 'grade_name': 'ผลมีขนาดใหญ่'},
//           {'grade_id': 'MEDIUM', 'grade_name': 'ผลมีขนาดปานกลาง'},
//           {'grade_id': 'BAD', 'grade_name': 'ผลเสีย (ตกเกรด)'},
//         ];

//       case 'farm_activity_type_id':
//         return [
//           {'farm_activity_type_id': 'WEEDING', 'farm_activity_type_name': 'ตัดหญ้า'},
//           {'farm_activity_type_id': 'HERBICIDE', 'farm_activity_type_name': 'พ่นยาฆ่าหญ้า'},
//           {'farm_activity_type_id': 'PRUNING', 'farm_activity_type_name': 'ตัดแต่งกิ่ง'},
//           {'farm_activity_type_id': 'CHEMICAL_FERTILIZING', 'farm_activity_type_name': 'ใส่ปุ๋ยเคมี'},
//           {'farm_activity_type_id': 'ORGANIC_FERTILIZING', 'farm_activity_type_name': 'ใส่ปุ๋ยคอก'},
//           {'farm_activity_type_id': 'INSECTICIDE', 'farm_activity_type_name': 'พ่นยาฆ่าแมลง'},
//           {'farm_activity_type_id': 'BIO_PRODUCT', 'farm_activity_type_name': 'พ่นสารชีวภัณฑ์'},
//           {'farm_activity_type_id': 'OTHER', 'farm_activity_type_name': 'อื่น ๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'fertilizer_application_stage_id':
//         return [
//           {'fertilizer_application_stage_id': 'STG00', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยรองก้นหลุม', 'fertilizer_application_stage_name_en': 'Basal Application'},
//           {'fertilizer_application_stage_id': 'STG04', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 4 เดือน', 'fertilizer_application_stage_name_en': '4 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG08', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 8 เดือน', 'fertilizer_application_stage_name_en': '8 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG12', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 12 เดือน', 'fertilizer_application_stage_name_en': '12 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG16', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 16 เดือน', 'fertilizer_application_stage_name_en': '16 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG20', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 20 เดือน', 'fertilizer_application_stage_name_en': '20 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG24', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 24 เดือน', 'fertilizer_application_stage_name_en': '24 Months Stage'},
//           {'fertilizer_application_stage_id': 'STG28', 'fertilizer_application_stage_name_th': 'ใส่ปุ๋ยเมื่ออายุครบ 28 เดือน', 'fertilizer_application_stage_name_en': '28 Months Stage'},
//         ];

//       case 'fertilizer_id':
//         return [
//           {'fertilizer_id': 'FER01', 'fertilizer_name': 'หินฟอสเฟต', 'is_organic': false, 'description': 'ปุ๋ยเคมีหินฟอสเฟตทั่วไป'},
//           {'fertilizer_id': 'FER02', 'fertilizer_name': 'ปุ๋ยเคมี 15-15-15', 'is_organic': false, 'description': 'ปุ๋ยเคมี สูตร 15-15-15 สำหรับใส่เมื่ออายุ 4-24 เดือน'},
//           {'fertilizer_id': 'FER03', 'fertilizer_name': 'ปุ๋ยเคมี 12-12-17-2', 'is_organic': false, 'description': 'ปุ๋ยเคมี สูตร 12-12-17-2 สำหรับใส่เมื่ออายุ 28 เดือน'},
//           {'fertilizer_id': 'FER04', 'fertilizer_name': 'ปุ๋ยหมักทั่วไป', 'is_organic': true, 'description': 'ปุ๋ยหมักหรือปุ๋ยชีวภาพ ใช้ปรับปรุงดิน'},
//           {'fertilizer_id': 'FER05', 'fertilizer_name': 'ปุ๋ยคอก', 'is_organic': true, 'description': 'ปุ๋ยอินทรีย์จากมูลสัตว์ ปรับปรุงความอุดมสมบูรณ์ของดิน'},
//           {'fertilizer_id': 'OTHER', 'fertilizer_name': 'อื่นๆ โปรดระบุที่หมายเหตุ', 'is_organic': true, 'description': 'ปุ๋ยอินทรีย์จากมูลสัตว์ ปรับปรุงความอุดมสมบูรณ์ของดิน'},
//         ];

//       case 'pest_disease_id':
//         return [
//           {'pest_disease_id': 'DIS_BP', 'pest_disease_name': 'โรคผลเน่าดำ (Black Pod)', 'pest_disease_type': 'DISEASE', 'description': 'เกิดจากเชื้อรา Phytophthora'},
//           {'pest_disease_id': 'PEST_CPB', 'pest_disease_name': 'หนอนเจาะผลโกโก้ (CPB)', 'pest_disease_type': 'PEST', 'description': 'Conopomorpha cramerella'},
//           {'pest_disease_id': 'PEST_APH', 'pest_disease_name': 'เพลี้ยอ่อน', 'pest_disease_type': 'PEST', 'description': 'ดูดกินน้ำเลี้ยงยอดอ่อน'},
//           {'pest_disease_id': 'OTHER', 'pest_disease_name': 'อื่นๆ โปรดระบุที่หมายเหตุ', 'pest_disease_type': 'PEST', 'description': 'ดูดกินน้ำเลี้ยงยอดอ่อน'},
//         ];

//       case 'tank_material_id':
//         return [
//           {'tank_material_id': 'WOOD', 'tank_material_name': 'ไม้ (นิยมที่สุดสำหรับกลิ่นหอม)'},
//           {'tank_material_id': 'PLASTIC', 'tank_material_name': 'พลาสติก Food Grade'},
//           {'tank_material_id': 'CONC', 'tank_material_name': 'คอนกรีต'},
//           {'tank_material_id': 'OTHER', 'tank_material_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'weather_condition_id':
//         return [
//           {'weather_condition_id': 'SUNNY', 'weather_condition_name': 'แดดจัด'},
//           {'weather_condition_id': 'CLOUDY', 'weather_condition_name': 'เมฆมาก'},
//           {'weather_condition_id': 'RAINY', 'weather_condition_name': 'ฝนตก'},
//           {'weather_condition_id': 'HUMID', 'weather_condition_name': 'ความชื้นสูง'},
//           {'weather_condition_id': 'OTHER', 'weather_condition_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'processing_activity_type_id':
//         return [
//           {'processing_activity_type_id': 'FERMENT', 'processing_activity_type_name': 'การหมัก'},
//           {'processing_activity_type_id': 'TURN', 'processing_activity_type_name': 'การกลับกอง/พลิกเมล็ด'},
//           {'processing_activity_type_id': 'DRY', 'processing_activity_type_name': 'การตากแห้ง'},
//           {'processing_activity_type_id': 'SORT', 'processing_activity_type_name': 'การคัดแยกเมล็ดเสีย'},
//           {'processing_activity_type_id': 'OTHER', 'processing_activity_type_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'processing_defect_id':
//         return [
//           {'processing_defect_id': 'MOLD', 'processing_defect_name': 'ราภายในเมล็ด'},
//           {'processing_defect_id': 'SLATY', 'processing_defect_name': 'เมล็ดสีเทา (ไม่เกิดการหมัก)'},
//           {'processing_defect_id': 'GERM', 'processing_defect_name': 'เมล็ดงอก'},
//           {'processing_defect_id': 'FLAT', 'processing_defect_name': 'เมล็ดฝีบ'},
//           {'processing_defect_id': 'OTHER', 'processing_defect_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'quantity_unit_id':
//         return [
//           {'quantity_unit_id': 'KG', 'quantity_unit_name': 'กิโลกรัม'},
//           {'quantity_unit_id': 'G', 'quantity_unit_name': 'กรัม'},
//           {'quantity_unit_id': 'L', 'quantity_unit_name': 'ลิตร'},
//           {'quantity_unit_id': 'UNIT', 'quantity_unit_name': 'ต้น/ผล'},
//           {'quantity_unit_id': 'OTHER', 'quantity_unit_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'water_source_id':
//         return [
//           {'water_source_id': 'NAT', 'water_source_name': 'แหล่งน้ำธรรมชาติ'},
//           {'water_source_id': 'WELL', 'water_source_name': 'น้ำบาดาล/บ่อขุด'},
//           {'water_source_id': 'MUN', 'water_source_name': 'น้ำประปา'},
//           {'water_source_id': 'OTHER', 'water_source_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'watering_system_id':
//         return [
//           {'watering_system_id': 'DRIP', 'watering_system_name': 'ระบบน้ำหยด'},
//           {'watering_system_id': 'SPRINK', 'watering_system_name': 'สปริงเกอร์'},
//           {'watering_system_id': 'MANUAL', 'watering_system_name': 'ตักรด/สายยาง'},
//           {'watering_system_id': 'OTHER', 'watering_system_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'land_type_id':
//         return [
//           {'land_type_id': 'FLAT', 'land_type_name': 'ที่ราบ'},
//           {'land_type_id': 'SLOPE', 'land_type_name': 'ที่ลาดชัน/เชิงเขา'},
//           {'land_type_id': 'VALLEY', 'land_type_name': 'ที่ลุ่ม'},
//           {'land_type_id': 'OTHER', 'land_type_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];

//       case 'soil_type_id':
//         return [
//           {'soil_type_id': 'LOAM', 'soil_type_name': 'ดินร่วน'},
//           {'soil_type_id': 'CLAY', 'soil_type_name': 'ดินเหนียว'},
//           {'soil_type_id': 'SANDY', 'soil_type_name': 'ดินร่วนปนทราย'},
//           {'soil_type_id': 'OTHER', 'soil_type_name': 'อื่นๆ โปรดระบุท่ี่หมายเหตุ'},
//         ];

//       case 'drying_facility_type_id':
//         return [
//           {'drying_facility_type_id': 'SUN_FLOOR', 'drying_facility_type_name': 'ลานตากปูนกลางแจ้ง'},
//           {'drying_facility_type_id': 'SOLAR_HOUSE', 'drying_facility_type_name': 'โรงตากพลังงานแสงอาทิตย์ (Para-dome)'},
//           {'drying_facility_type_id': 'SHADE', 'drying_facility_type_name': 'ตากในร่ม/อากาศถ่ายเท'},
//           {'drying_facility_type_id': 'OTHER', 'drying_facility_type_name': 'อื่นๆ โปรดระบุที่หมายเหตุ'},
//         ];
//       case 'chem_bio_id':
//         return [
//           {'chem_bio_id': 'HUMIC', 'chem_bio_name': 'ฮิวมิก (หน่วยเป็นซีซีต่อน้ำ 20 ลิตร)'},
//           {'chem_bio_id': 'OTHER', 'chem_bio_name': 'อื่นๆ โปรดระบุที่หมายเหตุ พร้อมหน่วย'},
//         ];  
//       case 'running_number':
//         return [
//           {'table_id': 'FM'},
//           {'table_id': 'FA'},
//           {'table_id': 'PS'},
//           {'table_id': 'PR'},
//           {'table_id': 'UA'},
//         ];

//       default:
//         return [];
//     }
//   } catch (_) {
//     return [];
//   }
// }
}
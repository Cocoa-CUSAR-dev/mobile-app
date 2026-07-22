import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class PolygonData {
  final List<LatLng> points;
  final double areaM2;
  PolygonData({required this.points, required this.areaM2});
  factory PolygonData.empty() => PolygonData(points: [], areaM2: 0);
}

class ThaiAreaUtils {
  static double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;
    double totalArea = 0;
    const double earthRadius = 6378137.0;
    for (int i = 0; i < points.length; i++) {
      var p1 = points[i];
      var p2 = points[(i + 1) % points.length];
      totalArea += (p2.longitude - p1.longitude).toRad() *
          (2 + math.sin(p1.latitude.toRad()) + math.sin(p2.latitude.toRad()));
    }
    return (totalArea * earthRadius * earthRadius / 2).abs();
  }

  static String format(double m2, int pointCount, [List<LatLng>? points]) {
    if (pointCount == 0) return "ยังไม่ได้ระบุตำแหน่ง";
    if (pointCount < 3) {
      if (points != null && points.isNotEmpty) {
        return "พิกัด: ${points.first.latitude.toStringAsFixed(6)}, ${points.first.longitude.toStringAsFixed(6)}";
      }
      return "ระบุพิกัดแล้ว";
    }
    int rai = (m2 / 1600).floor();
    int ngan = ((m2 - (rai * 1600)) / 400).floor();
    double wa = (m2 - (rai * 1600) - (ngan * 400)) / 4;
    return "$rai ไร่ $ngan งาน ${wa.toStringAsFixed(1)} วา²";
  }
}

class GISInput extends StatelessWidget {
  final String label;
  final bool isRequired;
  final PolygonData data;
  final ValueChanged<PolygonData> onChanged;

  const GISInput({
    super.key,
    required this.label,
    required this.isRequired,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasData = data.points.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label ${isRequired ? '*' : ''}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final PolygonData? result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapPolygonPicker(initialData: data)),
            );
            if (result != null) onChanged(result);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: hasData ? const Color(0xFF794c46) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: hasData ? const Color(0x1A794C46) : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: hasData ? const Color(0xFF794c46) : Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ThaiAreaUtils.format(data.areaM2, data.points.length, data.points),
                        style: TextStyle(
                          color: hasData ? Colors.black87 : Colors.grey.shade600,
                          fontSize: 18,
                          fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (hasData)
                        Text(data.points.length < 3 ? "ส่งค่าเป็น: พิกัด (1 จุด)" : "ส่งค่าเป็น: พื้นที่ (${data.points.length} จุด)",
                            style: const TextStyle(fontSize: 14, color: Color(0xFF794c46))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: hasData ? const Color(0xFF794c46) : Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MapPolygonPicker extends StatefulWidget {
  final PolygonData initialData;
  const MapPolygonPicker({super.key, required this.initialData});

  @override
  State<MapPolygonPicker> createState() => _MapPolygonPickerState();
}

class _MapPolygonPickerState extends State<MapPolygonPicker> {
  MaplibreMapController? _controller;
  late List<LatLng> _points;
  double _areaM2 = 0;
  bool _styleLoaded = false;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialData.points);
    _areaM2 = widget.initialData.areaM2;
  }

  void _updateState() {
    setState(() => _areaM2 = ThaiAreaUtils.calculateArea(_points));
    _drawOnMap();
  }

  Future<void> _drawOnMap() async {
    if (_controller == null || !_styleLoaded) return;
    
    await _controller!.clearSymbols();
    await _controller!.clearCircles(); // ล้างสัญลักษณ์วงกลมเก่า
    await _controller!.clearFills();
    await _controller!.clearLines();

    // 1. วาดสัญลักษณ์ (ใช้ Circle แทน Marker Icon เพื่อให้การันตีว่าสัญลักษณ์จะขึ้นแน่นอน)
    for (var i = 0; i < _points.length; i++) {
      // วาดวงกลมสีเข้มเป็นพื้นหลังหมุด
      await _controller!.addCircle(
        CircleOptions(
          geometry: _points[i],
          circleRadius: 12,
          circleColor: '#FFFFFF',
          circleStrokeWidth: 2,
          circleStrokeColor: '#888888',
          draggable: true,
        ),
        {'index': i},
      );

      // วาดตัวเลขกำกับ
      await _controller!.addSymbol(
        SymbolOptions(
          geometry: _points[i],
          textField: "${i + 1}",
          textSize: 12,
          textColor: '#FFFFFF',
          draggable: true,
        ),
        {'index': i},
      );
    }

    // 2. วาดพื้นที่ (ถ้ามี 3 จุดขึ้นไป)
    if (_points.length >= 3) {
      final polygonPath = List<LatLng>.from(_points)..add(_points.first);
      await _controller!.addFill(FillOptions(
        geometry: [polygonPath],
        fillColor: "#6B8E42",
        fillOpacity: 0.4,
      ));
      await _controller!.addLine(LineOptions(
        geometry: polygonPath,
        lineColor: "#4A622E",
        lineWidth: 3.0,
      ));
    }
  }

  // ฟังก์ชันขยับกล้องไปตำแหน่งปัจจุบันแบบรัดกุม
  void _goToCurrentLocation() async {
    if (_controller == null) return;
    try {
      final userLocation = await _controller!.requestMyLocationLatLng();
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation!, 16),
      );
    } catch (e) {
      // หากยังหาพิกัดไม่ได้ในทันที (เช่น GPS ยังไม่พร้อม)
      print("Waiting for GPS...");
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF794c46),
        foregroundColor: Colors.white,
        toolbarHeight: 64,
        title: Text(_points.length < 3 ? "ระบุตำแหน่ง (1 จุด)" : "ระบุพื้นที่ (3 จุดขึ้นไป)"),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_points.length == 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("กรุณาปักเพิ่มอีก 1 จุดเพื่อเป็นพื้นที่ หรือลบให้เหลือ 1 จุดเพื่อเป็นพิกัด"))
                );
                return;
              }
              Navigator.pop(context, PolygonData(points: _points, areaM2: _areaM2));
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text("บันทึก", style: TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            onMapCreated: (c) => _controller = c,
            onStyleLoadedCallback: () {
              _styleLoaded = true;
              if (_points.isNotEmpty) {
                _drawOnMap();
                _controller!.animateCamera(CameraUpdate.newLatLngZoom(_points.last, 14));
              } else {
                // หน่วงเวลาเล็กน้อยเพื่อให้ระบบ MyLocation พร้อมทำงาน
                Future.delayed(const Duration(milliseconds: 500), () {
                  _goToCurrentLocation();
                });
              }
            },
            // onSymbolDragEnd: (symbol) {
            //   final index = (symbol.data as Map)['index'] as int;
            //   setState(() {
            //     _points[index] = symbol.options.geometry!;
            //     _updateState();
            //   });
            // },
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7367, 100.5330), // จุฬาลงกรณ์มหาวิทยาลัย
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.compass,
            onMapClick: (_, latlng) {
              _points.add(latlng);
              _updateState();
            },
            styleString: "https://tiles.openfreemap.org/styles/liberty",
          ),
          
          // // เป้าเล็งกลางจอช่วยการปัก
          // if (_points.isEmpty)
          //   const Center(
          //     child: Padding(
          //       padding: EdgeInsetsGeometry.all(40),
          //       child: Icon(Icons.add_location_alt_outlined, size: 40, color: Color(0xFF794c46)),
          //     ),
          //   ),

          // แสดงข้อมูลด้านบน
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ThaiAreaUtils.format(_areaM2, _points.length, _points),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF794c46)),
                  ),
                  Text(
                    "กรุณาเลื่อนแผนที่ไปยังบริเวณที่ต้องการแล้วกดบนแผนที่เพื่อระบุตำแหน่ง หากต้องการระบุเพียงตำแหน่ง ให้ปัก 1 จุด แต่กรณีต้องการระบุพื้นที่กรุณาปัก 3 จุดขึ้นไป",
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  // if (_points.isNotEmpty)
                  //   const Text("กดค้างที่หมุดเพื่อลากย้ายตำแหน่งได้", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),

          // ปุ่มควบคุม
          Positioned(
            bottom: 30, right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: "gps",
                  backgroundColor: Colors.white,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location, color: Color(0xFF794c46)),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "undo",
                  backgroundColor: const Color(0xFF794c46),
                  onPressed: () {
                    if (_points.isNotEmpty) {
                      _points.removeLast();
                      _updateState();
                    }
                  },
                  child: const Icon(Icons.undo, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double toRad() => this * (math.pi / 180.0);
}
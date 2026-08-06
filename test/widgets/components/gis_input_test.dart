// Tests for lib/widgets/components/gis_input.dart.
//
// ThaiAreaUtils is pure math/formatting and is unit tested directly.
// GISInput's own build() (label + summary tile) is exercised as a widget
// test, but we never tap it — that would push MapPolygonPicker, which
// embeds a MapLibreMap platform view that flutter_test's widget-test
// environment can't render (no platform-view registry). Covers
// M-FARM-09/M-PLOT-13/M-STAT-10/M-HUB-10/M-FORM-04 "Area" fields' summary
// display and the "1 point = coordinate, 3+ points = area" rule that all
// of them share through this one component.

import 'package:cocoa_supply/widgets/components/gis_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ThaiAreaUtils.calculateArea', () {
    test('returns 0 for fewer than 3 points', () {
      expect(ThaiAreaUtils.calculateArea([]), 0);
      expect(ThaiAreaUtils.calculateArea([const LatLng(13.7, 100.5)]), 0);
      expect(
        ThaiAreaUtils.calculateArea([const LatLng(13.7, 100.5), const LatLng(13.71, 100.5)]),
        0,
      );
    });

    test('returns a positive area for a real polygon', () {
      final area = ThaiAreaUtils.calculateArea([
        const LatLng(13.700, 100.500),
        const LatLng(13.700, 100.501),
        const LatLng(13.701, 100.501),
        const LatLng(13.701, 100.500),
      ]);
      expect(area, greaterThan(0));
    });
  });

  group('ThaiAreaUtils.format', () {
    test('0 points shows the "not yet specified" message', () {
      expect(ThaiAreaUtils.format(0, 0), 'ยังไม่ได้ระบุตำแหน่ง');
    });

    test('1-2 points shows the raw coordinate of the first point', () {
      final points = [const LatLng(13.700000, 100.500000)];
      expect(ThaiAreaUtils.format(0, 1, points), 'พิกัด: 13.700000, 100.500000');
    });

    test('3+ points converts m2 into rai/ngan/wa', () {
      // 1600 m2 = 1 rai exactly.
      expect(ThaiAreaUtils.format(1600, 3), '1 ไร่ 0 งาน 0.0 วา²');
      // 1600 + 400 = 1 rai 1 ngan.
      expect(ThaiAreaUtils.format(2000, 4), '1 ไร่ 1 งาน 0.0 วา²');
    });
  });

  group('GISInput', () {
    testWidgets('shows the "not yet specified" placeholder with no points', (tester) async {
      await tester.pumpWidget(wrap(GISInput(
        label: 'พื้นที่แปลง',
        isRequired: true,
        data: PolygonData.empty(),
        onChanged: (_) {},
      )));

      expect(find.text('พื้นที่แปลง *'), findsOneWidget);
      expect(find.text('ยังไม่ได้ระบุตำแหน่ง'), findsOneWidget);
    });

    testWidgets('a single point is summarized as a coordinate', (tester) async {
      await tester.pumpWidget(wrap(GISInput(
        label: 'พื้นที่แปลง',
        isRequired: false,
        data: PolygonData(points: const [LatLng(13.7, 100.5)], areaM2: 0),
        onChanged: (_) {},
      )));

      expect(find.text('พิกัด: 13.700000, 100.500000'), findsOneWidget);
      expect(find.text('ส่งค่าเป็น: พิกัด (1 จุด)'), findsOneWidget);
    });

    testWidgets('3+ points is summarized as an area', (tester) async {
      await tester.pumpWidget(wrap(GISInput(
        label: 'พื้นที่แปลง',
        isRequired: false,
        data: PolygonData(
          points: const [
            LatLng(13.700, 100.500),
            LatLng(13.700, 100.501),
            LatLng(13.701, 100.501),
          ],
          areaM2: 1600,
        ),
        onChanged: (_) {},
      )));

      expect(find.text('1 ไร่ 0 งาน 0.0 วา²'), findsOneWidget);
      expect(find.text('ส่งค่าเป็น: พื้นที่ (3 จุด)'), findsOneWidget);
    });
  });
}

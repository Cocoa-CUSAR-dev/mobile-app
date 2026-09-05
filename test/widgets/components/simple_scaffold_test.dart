// Widget tests for lib/widgets/components/simple_scaffold.dart.

import 'package:cocoa_supply/widgets/components/simple_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimpleScaffold', () {
    testWidgets('shows the title and body', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SimpleScaffold(title: 'ลงทะเบียนฟาร์ม', body: Text('body content')),
      ));

      expect(find.text('ลงทะเบียนฟาร์ม'), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('showBackButton:false hides the back arrow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SimpleScaffold(title: 'ลงทะเบียนฟาร์ม', body: Text('body'), showBackButton: false),
      ));

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('tapping back awaits onBeforePop before popping', (tester) async {
      var beforePopCalled = false;
      await tester.pumpWidget(MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => SimpleScaffold(
              title: 'หน้าแรก',
              body: const Text('body'),
              onBeforePop: () async {
                beforePopCalled = true;
              },
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(beforePopCalled, isTrue);
    });
  });
}

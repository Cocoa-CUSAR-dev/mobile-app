// Widget tests for lib/widgets/pages/dynamic_register_page.dart.
//
// Environment limitation confirmed by direct investigation: once any
// widget has been pumped in a test (tester.pumpWidget), a
// rootBundle.loadString() awaited *inside a Bloc event handler* never
// resolves, no matter how much fake-clock time is pumped afterward —
// even with the schema pre-cached via a setUpAll rootBundle.loadString()
// call beforehand, and even calling bloc.add() fresh after the pump. The
// exact same DynamicBloc code resolves fine in
// test/bloc/dynamic/dynamic_bloc_test.dart, whose blocTest() helper never
// calls pumpWidget at all — so the schema-loading and field-rendering
// behavior itself is already covered there (including the "unknown
// handler -> DynamicError" case). These page-level tests are limited to
// what's observable before that unresolvable await: the initial loading
// state renders and the page mounts without throwing.

import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';
import 'package:cocoa_supply/widgets/pages/dynamic_register_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'page_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows a loading indicator while the schema loads', (tester) async {
    await tester.pumpWidget(wrapPage(
      const DynamicRegisterPage(handler: 'farmer', taskId: 't1', status: 'NOT_STARTED'),
    ));
    await tester.pump();

    expect(find.byType(ThreeDotsLoading), findsOneWidget);
  });

  testWidgets('mounts without throwing for an unknown handler too', (tester) async {
    await tester.pumpWidget(wrapPage(
      const DynamicRegisterPage(handler: 'no_such_table', taskId: 't1', status: 'NOT_STARTED'),
    ));
    await tester.pump();

    expect(find.byType(DynamicRegisterPage), findsOneWidget);
  });
}

// Unit tests for submitting the link form in lib/bloc/login/liff_login_bloc.dart.

import 'package:bloc_test/bloc_test.dart';
import 'package:cocoa_supply/bloc/login/liff_login_bloc.dart';
import 'package:cocoa_supply/bloc/login/liff_login_event.dart';
import 'package:cocoa_supply/bloc/login/liff_login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const submit = LiffLoginSubmitted(username: '0812345678', password: 'cocoa1234');

  blocTest<LiffLoginBloc, LiffLoginState>(
    'the form can be sent again after a refused submit',
    build: () => LiffLoginBloc(
      client: MockClient((request) async {
        expect(request.url.toString(), '$testBaseUrl/api/v1/auth/line/link');
        return jsonResponse(tokenPairJson(roles: ['farmer']), 200);
      }),
    ),
    seed: () => const LiffLoginFailure(error: 'wrong password', idToken: 'line-token'),
    act: (bloc) => bloc.add(submit),
    expect: () => [
      isA<LiffLoginLoading>().having((s) => s.idToken, 'idToken', 'line-token'),
      isA<LiffLoginSuccess>().having((s) => s.hasProfile, 'hasProfile', true),
    ],
  );

  blocTest<LiffLoginBloc, LiffLoginState>(
    'without an idToken there is nothing to send',
    build: () => LiffLoginBloc(
      client: MockClient((request) async => throw StateError('should not be called')),
    ),
    seed: () => const LiffLoginFailure(error: 'liff.init failed'),
    act: (bloc) => bloc.add(submit),
    expect: () => [
      isA<LiffLoginFailure>().having((s) => s.idToken, 'idToken', isNull),
    ],
  );
}

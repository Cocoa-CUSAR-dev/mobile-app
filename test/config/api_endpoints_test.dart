import 'dart:io';

import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// The paths of the merged backend (the After sheet of api-migration-map.xlsx),
// written out in full. If one has to change, change it here on purpose: this is
// the list of what the app asks the backend for.
void main() {
  group('ApiEndpoints', () {
    test('paths are exactly what the backend serves', () {
      expect(ApiEndpoints.authLogin, '/api/v1/auth/login');
      expect(ApiEndpoints.authRegister, '/api/v1/auth/register');
      expect(ApiEndpoints.authRefresh, '/api/v1/auth/refresh');
      expect(ApiEndpoints.authLogout, '/api/v1/auth/logout');
      expect(ApiEndpoints.authLineLink, '/api/v1/auth/line/link');
      expect(ApiEndpoints.me, '/api/v1/me');
      expect(ApiEndpoints.tasks, '/api/v1/tasks');
      expect(ApiEndpoints.farms, '/api/v1/agriculture/farms');
      expect(ApiEndpoints.plots, '/api/v1/agriculture/plots');
      expect(ApiEndpoints.hubs, '/api/v1/collection/hubs');
      expect(ApiEndpoints.harvests, '/api/v1/collection/harvests');
      expect(ApiEndpoints.processingStations, '/api/v1/processing/stations');
      expect(ApiEndpoints.batches, '/api/v1/processing/batches');
    });

    test('built paths keep their shape', () {
      expect(ApiEndpoints.meRole('farmer'), '/api/v1/me/roles/farmer');
      expect(
        ApiEndpoints.meRole('hub_collector'),
        '/api/v1/me/roles/hub_collector',
      );
      expect(ApiEndpoints.taskResponses('t1'), '/api/v1/tasks/t1/responses');
      expect(
        ApiEndpoints.taskResponse('t1', 'r1'),
        '/api/v1/tasks/t1/responses/r1',
      );
      expect(
        ApiEndpoints.constants('province'),
        '/api/v1/ref/constants/province',
      );
    });

    test('the two paths no backend serves are kept as they were', () {
      expect(ApiEndpoints.harvestGradeDetails, '/harvest_grade_details');
      expect(ApiEndpoints.table('farm_activities'), '/farm_activities');
    });
  });

  group('apiGroupOf', () {
    test('names the group from the first segment after /api/v1/', () {
      expect(apiGroupOf(ApiEndpoints.authLogin), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.authRefresh), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.authLineLink), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.me), ApiGroup.me);
      expect(apiGroupOf(ApiEndpoints.meRole('farmer')), ApiGroup.me);
      expect(apiGroupOf(ApiEndpoints.tasks), ApiGroup.tasks);
      expect(apiGroupOf('/api/v1/tasks/t1/form'), ApiGroup.tasks);
      expect(apiGroupOf(ApiEndpoints.farms), ApiGroup.agriculture);
      expect(apiGroupOf(ApiEndpoints.plots), ApiGroup.agriculture);
      expect(apiGroupOf(ApiEndpoints.hubs), ApiGroup.collection);
      expect(apiGroupOf(ApiEndpoints.harvests), ApiGroup.collection);
      expect(apiGroupOf(ApiEndpoints.processingStations), ApiGroup.processing);
      expect(apiGroupOf(ApiEndpoints.batches), ApiGroup.processing);
      expect(apiGroupOf(ApiEndpoints.constants('province')), ApiGroup.ref);
    });

    test('puts anything outside /api/v1/, or no path at all, in "other"', () {
      expect(apiGroupOf(ApiEndpoints.harvestGradeDetails), ApiGroup.other);
      expect(apiGroupOf(ApiEndpoints.table('farm_activities')), ApiGroup.other);
      expect(apiGroupOf('/api/v1/unknown/x'), ApiGroup.other);
      expect(apiGroupOf(''), ApiGroup.other);
    });
  });

  group('resolveApiBaseUrl', () {
    const fallback = 'https://old.example';

    test('uses the default when the group has no override', () {
      expect(resolveApiBaseUrl(ApiGroup.tasks, {}, fallback), fallback);
    });

    test('treats an empty override as not set', () {
      expect(
        resolveApiBaseUrl(ApiGroup.tasks, {ApiGroup.tasks: ''}, fallback),
        fallback,
      );
    });

    test('sends only the overridden group to its own backend', () {
      const overrides = {ApiGroup.tasks: 'https://new.example'};

      expect(
        resolveApiBaseUrl(ApiGroup.tasks, overrides, fallback),
        'https://new.example',
      );
      expect(
        resolveApiBaseUrl(ApiGroup.agriculture, overrides, fallback),
        fallback,
      );
    });
  });

  group('ServiceProvider', () {
    test(
      'with no build-time overrides every group uses the default backend',
      () {
        for (final endpoint in [
          ApiEndpoints.tasks,
          ApiEndpoints.me,
          ApiEndpoints.farms,
          ApiEndpoints.table('anything'),
        ]) {
          final provider = ServiceProvider(storageKey: 'k', endpoint: endpoint);
          expect(provider.baseUrl, defaultApiBaseUrl);
        }
      },
    );
  });

  // The map only helps if nothing goes around it.
  group('no backend path outside lib/config/api_endpoints.dart', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => !f.path
              .replaceAll(r'\', '/')
              .endsWith('lib/config/api_endpoints.dart'),
        );

    test('no service or page names an endpoint as a string', () {
      final literal = RegExp(r'''endpoint:\s*['"]/''');
      final offenders = [
        for (final f in files)
          if (literal.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(offenders, isEmpty);
    });

    test('nothing builds a backend URL from a path by hand', () {
      final byHand = RegExp(r'''['"]\$baseUrl/''');
      final offenders = [
        for (final f in files)
          if (byHand.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}

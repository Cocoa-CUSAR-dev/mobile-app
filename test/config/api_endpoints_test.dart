import 'dart:io';

import 'package:cocoa_supply/config/api_endpoints.dart';
import 'package:cocoa_supply/services/service_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// The paths the backend serves today, written out in full. If one has to
// change, change it here on purpose: this is the list of what the app asks
// the backend for.
void main() {
  group('ApiEndpoints', () {
    test('paths are exactly what the backend serves', () {
      expect(ApiEndpoints.authMe, '/auth/me');
      expect(ApiEndpoints.publicLogin, '/public/login');
      expect(ApiEndpoints.publicRegister, '/public/register');
      expect(ApiEndpoints.publicLiffLink, '/public/liff/link');
      expect(ApiEndpoints.tasks, '/tasks');
      expect(ApiEndpoints.farms, '/farms');
      expect(ApiEndpoints.plots, '/plots');
      expect(ApiEndpoints.hubs, '/hubs');
      // "batchs" is how the backend spells it.
      expect(ApiEndpoints.batches, '/batchs');
      expect(ApiEndpoints.harvests, '/harvests');
      expect(ApiEndpoints.harvestGradeDetails, '/harvest_grade_details');
      expect(ApiEndpoints.processingStations, '/processing_stations');
      expect(ApiEndpoints.farmers, '/farmers');
      expect(ApiEndpoints.processors, '/processors');
      expect(ApiEndpoints.hubCollectors, '/hub_collectors');
    });

    test('built paths keep their shape', () {
      expect(ApiEndpoints.constants('province'), '/constants/province');
      expect(ApiEndpoints.table('farm_activities'), '/farm_activities');
    });
  });

  group('apiGroupOf', () {
    test('names the group from the first path segment', () {
      expect(apiGroupOf(ApiEndpoints.authMe), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.publicLogin), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.publicLiffLink), ApiGroup.auth);
      expect(apiGroupOf(ApiEndpoints.tasks), ApiGroup.tasks);
      expect(apiGroupOf('/tasks/t1/form'), ApiGroup.tasks);
      expect(apiGroupOf(ApiEndpoints.farms), ApiGroup.farms);
      expect(apiGroupOf(ApiEndpoints.plots), ApiGroup.plots);
      expect(apiGroupOf(ApiEndpoints.hubs), ApiGroup.hubs);
      expect(apiGroupOf(ApiEndpoints.batches), ApiGroup.batches);
      expect(apiGroupOf(ApiEndpoints.harvests), ApiGroup.harvests);
      expect(
        apiGroupOf(ApiEndpoints.harvestGradeDetails),
        ApiGroup.harvestGradeDetails,
      );
      expect(
        apiGroupOf(ApiEndpoints.processingStations),
        ApiGroup.processingStations,
      );
      expect(apiGroupOf(ApiEndpoints.farmers), ApiGroup.farmers);
      expect(apiGroupOf(ApiEndpoints.processors), ApiGroup.processors);
      expect(apiGroupOf(ApiEndpoints.hubCollectors), ApiGroup.hubCollectors);
      expect(apiGroupOf(ApiEndpoints.constants('province')), ApiGroup.constants);
    });

    test('puts anything else, or no path at all, in "other"', () {
      expect(apiGroupOf(ApiEndpoints.table('farm_activities')), ApiGroup.other);
      expect(apiGroupOf(''), ApiGroup.other);
      expect(apiGroupOf('/'), ApiGroup.other);
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
      expect(resolveApiBaseUrl(ApiGroup.farms, overrides, fallback), fallback);
    });
  });

  group('ServiceProvider', () {
    test('with no build-time overrides every group uses the default backend', () {
      for (final endpoint in [
        ApiEndpoints.tasks,
        ApiEndpoints.authMe,
        ApiEndpoints.farms,
        ApiEndpoints.table('anything'),
      ]) {
        final provider = ServiceProvider(storageKey: 'k', endpoint: endpoint);
        expect(provider.baseUrl, defaultApiBaseUrl);
      }
    });
  });

  // The map only helps if nothing goes around it.
  group('no backend path outside lib/config/api_endpoints.dart', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.replaceAll(r'\', '/').endsWith('lib/config/api_endpoints.dart'));

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

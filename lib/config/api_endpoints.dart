// Every backend path the app calls, and which backend serves it.
//
// Nothing else in lib/ writes a path: services and pages pass one of the
// constants below to ServiceProvider. Each path belongs to an [ApiGroup] (the
// first segment of the path), and a group can be sent to its own backend at
// build time, so the app can move to a new backend one group at a time:
//
//   --dart-define=API_BASE_URL=https://old-backend            (every group)
//   --dart-define=API_BASE_URL_TASKS=https://new-backend      (just /tasks...)
//
// A group with no API_BASE_URL_<GROUP> of its own uses API_BASE_URL, so with
// no extra defines nothing changes.

/// Where a path is served. Named after the first path segment.
enum ApiGroup {
  auth, // /auth/..., /public/...
  tasks,
  farms,
  plots,
  hubs,
  batches,
  harvests,
  harvestGradeDetails,
  processingStations,
  farmers,
  processors,
  hubCollectors,
  constants,
  other,
}

abstract final class ApiEndpoints {
  static const String authMe = '/auth/me';
  static const String publicLogin = '/public/login';
  static const String publicRegister = '/public/register';
  static const String publicLiffLink = '/public/liff/link';

  static const String tasks = '/tasks';
  static const String farms = '/farms';
  static const String plots = '/plots';
  static const String hubs = '/hubs';
  // Spelled like this on the backend.
  static const String batches = '/batchs';
  static const String harvests = '/harvests';
  static const String harvestGradeDetails = '/harvest_grade_details';
  static const String processingStations = '/processing_stations';

  static const String farmers = '/farmers';
  static const String processors = '/processors';
  static const String hubCollectors = '/hub_collectors';

  /// A reference list, e.g. province or district.
  static String constants(String key) => '/constants/$key';

  /// A table the dynamic form saves to, named by the form.
  static String table(String name) => '/$name';
}

const Map<String, ApiGroup> _groupBySegment = {
  'auth': ApiGroup.auth,
  'public': ApiGroup.auth,
  'tasks': ApiGroup.tasks,
  'farms': ApiGroup.farms,
  'plots': ApiGroup.plots,
  'hubs': ApiGroup.hubs,
  'batchs': ApiGroup.batches,
  'harvests': ApiGroup.harvests,
  'harvest_grade_details': ApiGroup.harvestGradeDetails,
  'processing_stations': ApiGroup.processingStations,
  'farmers': ApiGroup.farmers,
  'processors': ApiGroup.processors,
  'hub_collectors': ApiGroup.hubCollectors,
  'constants': ApiGroup.constants,
};

/// The group a path belongs to; [ApiGroup.other] for one the app has no
/// constant for (a path built from a form's table name, or none at all).
ApiGroup apiGroupOf(String endpoint) {
  final segments = endpoint.split('/').where((s) => s.isNotEmpty);
  if (segments.isEmpty) return ApiGroup.other;
  return _groupBySegment[segments.first] ?? ApiGroup.other;
}

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mobile-backend-2-t8h6.onrender.com',
);

// Dart reads these at build time, and only from a literal name, so each group
// is spelled out. An empty value means "not set".
const Map<ApiGroup, String> _baseUrlOverrides = {
  ApiGroup.auth: String.fromEnvironment('API_BASE_URL_AUTH'),
  ApiGroup.tasks: String.fromEnvironment('API_BASE_URL_TASKS'),
  ApiGroup.farms: String.fromEnvironment('API_BASE_URL_FARMS'),
  ApiGroup.plots: String.fromEnvironment('API_BASE_URL_PLOTS'),
  ApiGroup.hubs: String.fromEnvironment('API_BASE_URL_HUBS'),
  ApiGroup.batches: String.fromEnvironment('API_BASE_URL_BATCHES'),
  ApiGroup.harvests: String.fromEnvironment('API_BASE_URL_HARVESTS'),
  ApiGroup.harvestGradeDetails:
      String.fromEnvironment('API_BASE_URL_HARVEST_GRADE_DETAILS'),
  ApiGroup.processingStations:
      String.fromEnvironment('API_BASE_URL_PROCESSING_STATIONS'),
  ApiGroup.farmers: String.fromEnvironment('API_BASE_URL_FARMERS'),
  ApiGroup.processors: String.fromEnvironment('API_BASE_URL_PROCESSORS'),
  ApiGroup.hubCollectors: String.fromEnvironment('API_BASE_URL_HUB_COLLECTORS'),
  ApiGroup.constants: String.fromEnvironment('API_BASE_URL_CONSTANTS'),
  ApiGroup.other: String.fromEnvironment('API_BASE_URL_OTHER'),
};

/// The backend a group is served from.
String apiBaseUrlFor(ApiGroup group) =>
    resolveApiBaseUrl(group, _baseUrlOverrides, defaultApiBaseUrl);

/// [apiBaseUrlFor] with its inputs passed in, so it can be tested without a
/// rebuild.
String resolveApiBaseUrl(
  ApiGroup group,
  Map<ApiGroup, String> overrides,
  String defaultBaseUrl,
) {
  final override = overrides[group];
  return (override == null || override.isEmpty) ? defaultBaseUrl : override;
}

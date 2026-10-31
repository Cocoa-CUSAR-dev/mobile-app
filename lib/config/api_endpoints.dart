// Every backend path the app calls, and which backend serves it.
//
// Nothing else in lib/ writes a path: services and pages pass one of the
// constants below to ServiceProvider. The paths are the After sheet of
// api-migration-map.xlsx: the one backend that replaces mobile-backend (Go)
// and web-backend (Kotlin). Each path belongs to an [ApiGroup], the first
// segment after /api/v1/, and a group can be sent to its own backend at build
// time, so the app can move over one group at a time:
//
//   --dart-define=API_BASE_URL=https://backend                 (every group)
//   --dart-define=API_BASE_URL_TASKS=https://other-backend     (just tasks)
//
// A group with no API_BASE_URL_<GROUP> of its own uses API_BASE_URL.
//
// The old mobile-backend paths that changed, for anyone reading an old log:
//   /public/login, /public/register       -> /api/v1/auth/login, /register
//   /public/liff/link                     -> /api/v1/auth/line/link
//   /auth/me                              -> /api/v1/me
//   POST /farmers, /hub_collectors,
//        /processors                      -> POST /api/v1/me/roles/{role}
//   /farms, /plots                        -> /api/v1/agriculture/farms, /plots
//   /hubs, /harvests                      -> /api/v1/collection/hubs, /harvests
//   /processing_stations, /batchs         -> /api/v1/processing/stations, /batches
//   /constants/{key}                      -> /api/v1/ref/constants/{key}
//   POST /tasks (task id in the body)     -> POST /api/v1/tasks/{id}/responses
//   PUT /tasks (ids in the body)          -> PUT /api/v1/tasks/{id}/responses/{rid}

/// Where a path is served. Named after the first segment after /api/v1/.
enum ApiGroup {
  auth,
  me,
  tasks,
  agriculture,
  collection,
  processing,
  ref,
  other,
}

abstract final class ApiEndpoints {
  static const String authLogin = '/api/v1/auth/login';
  static const String authRegister = '/api/v1/auth/register';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String authLogout = '/api/v1/auth/logout';
  // Link a LINE account to an existing account, then sign in.
  static const String authLineLink = '/api/v1/auth/line/link';

  /// Who I am: my account, my roles and a profile for each role.
  static const String me = '/api/v1/me';

  /// Add a role (farmer, hub_collector or processor) to myself.
  static String meRole(String role) => '/api/v1/me/roles/$role';

  /// Edit one of my role profiles (only the fields sent change).
  static String meProfile(String role) => '/api/v1/me/profiles/$role';

  static const String tasks = '/api/v1/tasks';
  static String taskResponses(String taskId) =>
      '/api/v1/tasks/$taskId/responses';
  static String taskResponse(String taskId, String responseId) =>
      '/api/v1/tasks/$taskId/responses/$responseId';

  static const String farms = '/api/v1/agriculture/farms';
  static const String plots = '/api/v1/agriculture/plots';
  static const String hubs = '/api/v1/collection/hubs';
  static const String harvests = '/api/v1/collection/harvests';
  static const String processingStations = '/api/v1/processing/stations';
  static const String batches = '/api/v1/processing/batches';

  /// A reference list, e.g. province or district.
  static String constants(String key) => '/api/v1/ref/constants/$key';

  // No backend serves this one (the migration map lists it as a bug), so it
  // keeps its old path until someone decides what to do with the screen.
  static const String harvestGradeDetails = '/harvest_grade_details';

  /// A table the dynamic form saves to, named by the form. Also unmapped.
  static String table(String name) => '/$name';
}

const String _apiPrefix = '/api/v1/';

const Map<String, ApiGroup> _groupBySegment = {
  'auth': ApiGroup.auth,
  'me': ApiGroup.me,
  'tasks': ApiGroup.tasks,
  'agriculture': ApiGroup.agriculture,
  'collection': ApiGroup.collection,
  'processing': ApiGroup.processing,
  'ref': ApiGroup.ref,
};

/// The group a path belongs to; [ApiGroup.other] for one outside /api/v1/.
ApiGroup apiGroupOf(String endpoint) {
  if (!endpoint.startsWith(_apiPrefix)) return ApiGroup.other;
  final segment = endpoint
      .substring(_apiPrefix.length)
      .split(RegExp(r'[/?]'))
      .first;
  return _groupBySegment[segment] ?? ApiGroup.other;
}

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mobile-backend-2-t8h6.onrender.com',
);

// Dart reads these at build time, and only from a literal name, so each group
// is spelled out. An empty value means "not set".
const Map<ApiGroup, String> _baseUrlOverrides = {
  ApiGroup.auth: String.fromEnvironment('API_BASE_URL_AUTH'),
  ApiGroup.me: String.fromEnvironment('API_BASE_URL_ME'),
  ApiGroup.tasks: String.fromEnvironment('API_BASE_URL_TASKS'),
  ApiGroup.agriculture: String.fromEnvironment('API_BASE_URL_AGRICULTURE'),
  ApiGroup.collection: String.fromEnvironment('API_BASE_URL_COLLECTION'),
  ApiGroup.processing: String.fromEnvironment('API_BASE_URL_PROCESSING'),
  ApiGroup.ref: String.fromEnvironment('API_BASE_URL_REF'),
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

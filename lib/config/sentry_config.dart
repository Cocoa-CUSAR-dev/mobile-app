// lib/config/sentry_config.dart
// X-2d: error tracking. Set at build/run time via
// --dart-define=SENTRY_DSN=... (same pattern as API_BASE_URL in
// service_provider.dart and LIFF_ID above). Empty DSN (the default)
// disables the SDK entirely -- safe for local dev/CI builds.
const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'local');

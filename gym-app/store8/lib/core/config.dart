/// Nothing here is hardcoded — the backend URL is passed in at build/run time so the same
/// code works for local dev, staging and production without editing source.
///
/// Defaults to the deployed production backend (https://gym-backend-sand.vercel.app) so a
/// plain `flutter run` / `flutter build apk` with no extra flags talks to the real API. To
/// point at a local dev server instead, override it explicitly:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000        (Android emulator -> localhost)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000       (Chrome/web -> localhost)
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gymbackendorg.vercel.app',
  );

  /// Only needed if you build this app for the web (Firebase Web Push requires it) — see
  /// SETUP.md step 4. Android/iOS ignore this entirely.
  static const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
}

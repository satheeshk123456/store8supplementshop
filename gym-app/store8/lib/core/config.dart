/// Backend URL defaults to the live production API below, so a plain `flutter build apk` /
/// `flutter run` just works with no extra flags. Override with --dart-define=API_BASE_URL=...
/// only if you need to point at a different backend (e.g. local dev): see examples below.
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   (Android emulator -> localhost)
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gymbackendorg.vercel.app',
  );

  /// Only needed if you build this app for the web (Firebase Web Push requires it) — see
  /// SETUP.md step 4. Android/iOS ignore this entirely.
  static const fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
}

// PLACEHOLDER — generated files like this are normally created for you by the FlutterFire CLI.
// Once you have your Firebase project (see ../SETUP.md), run this from gym-app/store8/:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// That command overwrites this entire file with your project's real Android/iOS/Web keys and
// also drops the correct google-services.json / GoogleService-Info.plist into android/app and
// ios/Runner for you. Nothing below is a secret that needs hiding (Firebase client config is
// meant to be embedded in apps — it's not an API key in the traditional sense; access is
// controlled by Firestore/Storage rules and, in this app's case, by the backend's own
// Firebase-Auth-token check), but it DOES have to be real for the app to build and connect.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform. '
          'Run `flutterfire configure` after setting up your Firebase project.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDJxvtubYvv0bjdnPSL2NAp4iHl8NWSyWI',
    appId: '1:326403588670:web:640f151c0420f47b78876f',
    messagingSenderId: '326403588670',
    projectId: 'store-8-tech',
    authDomain: 'store-8-tech.firebaseapp.com',
    storageBucket: 'store-8-tech.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDr6OI1cnhed9_y0eDPaOJZXxILIWj8vrU',
    appId: '1:326403588670:android:c8b798e88bcbd04778876f',
    messagingSenderId: '326403588670',
    projectId: 'store-8-tech',
    storageBucket: 'store-8-tech.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_flutterfire_configure',
    appId: 'REPLACE_WITH_flutterfire_configure',
    messagingSenderId: 'REPLACE_WITH_flutterfire_configure',
    projectId: 'REPLACE_WITH_flutterfire_configure',
    storageBucket: 'REPLACE_WITH_flutterfire_configure',
    // Matches ios/Runner's PRODUCT_BUNDLE_IDENTIFIER and android/app/build.gradle.kts'
    // applicationId (both still the Flutter default "com.example.store8" — see the TODO in
    // build.gradle.kts if you rename it before publishing).
    iosBundleId: 'com.example.store8',
  );
}

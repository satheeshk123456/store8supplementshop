import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../notifications/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AdminProfile {
  final String uid;
  final String email;
  final String name;
  final String role;
  AdminProfile({required this.uid, required this.email, required this.name, required this.role});

  factory AdminProfile.fromJson(Map<String, dynamic> json) => AdminProfile(
        uid: json['uid'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'staff',
      );
}

/// Owns the whole admin session: Firebase Auth sign-in + the backend's authorization check
/// (see gym-backend/app/security.py — being logged into Firebase isn't enough by itself, the
/// uid also has to be listed in the `admins` collection) + FCM device-token registration.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  final NotificationService _notifications;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthProvider(this._api, this._notifications) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  AuthStatus status = AuthStatus.unknown;
  AdminProfile? profile;
  String? errorMessage;
  bool isBusy = false;

  /// Firebase auth state often resolves in milliseconds, which would otherwise skip straight
  /// past the splash video. The router (see core/router.dart) also waits on this flag before
  /// leaving /splash — the splash screen calls completeIntro() once its video has finished (or
  /// timed out), and only then does the real login/dashboard redirect happen.
  bool introComplete = false;

  void completeIntro() {
    if (introComplete) return;
    introComplete = true;
    notifyListeners();
  }

  Future<String?> getIdToken() => _auth.currentUser?.getIdToken() ?? Future.value(null);

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      status = AuthStatus.unauthenticated;
      profile = null;
      notifyListeners();
      return;
    }
    await _verifyAdminAndLoadProfile();
  }

  Future<void> _verifyAdminAndLoadProfile() async {
    try {
      final data = await _api.get('/admin/me');
      profile = AdminProfile.fromJson(Map<String, dynamic>.from(data));
      status = AuthStatus.authenticated;
      errorMessage = null;
      notifyListeners();
      // Best-effort — a failed token registration shouldn't block login.
      unawaited(_notifications.registerTokenWithBackend());
    } on ApiException catch (e) {
      // Signed into Firebase but not on the admins allow-list (or session expired) -> sign out.
      errorMessage = e.statusCode == 403
          ? 'This account is not authorized as a Store 8 admin. Contact the store owner.'
          : e.message;
      await _auth.signOut();
      status = AuthStatus.unauthenticated;
      profile = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      // authStateChanges() listener above will run _verifyAdminAndLoadProfile automatically,
      // but we await it here too so the login screen knows when it's safe to navigate.
      await _verifyAdminAndLoadProfile();
      return status == AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyAuthError(e.code);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _notifications.unregisterTokenFromBackend();
    await _auth.signOut();
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Could not sign in. Please try again.';
    }
  }
}

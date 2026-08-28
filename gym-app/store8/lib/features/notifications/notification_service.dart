import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../firebase_options.dart';

/// Must match the channel_id the backend sends in AndroidNotification (see
/// gym-backend/app/notifications.py). Android will only show a heads-up notification while
/// the app is backgrounded/closed if a channel with this exact id exists on the device *and*
/// is high importance — that channel is created once below, the first time the app runs.
const kOrdersChannelId = 'orders_high_importance';
const kOrdersChannelName = 'New orders';

/// Runs in a separate background isolate when a push arrives while the app is backgrounded or
/// fully closed — Android wakes this isolate up on its own, which is exactly what makes "still
/// get the notification when the app is closed" work with zero extra plumbing. It must be a
/// top-level (or static) function and re-initialize Firebase itself, since this isolate doesn't
/// share state with the running app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Nothing else to do here: because the backend sends a `notification` payload (not just
  // `data`), Android/iOS display the system tray notification automatically in this state —
  // this handler exists so we could react to the data payload later if needed (e.g. syncing a
  // local badge count) without missing messages while the UI isn't running.
}

class NotificationService {
  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Set by the router once it's built, so a tapped notification can navigate even though this
  /// service has no BuildContext of its own.
  void Function(String orderId)? onOrderTapped;

  NotificationService(this._api);

  Future<void> init() async {
    await _createAndroidChannel();
    await _initLocalNotifications();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    // iOS: show system banners even while the app is in the foreground.
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    _messaging.onTokenRefresh.listen((_) => registerTokenWithBackend());

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage);
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      kOrdersChannelId,
      kOrdersChannelName,
      description: 'Alerts you the moment a customer places an order',
      importance: Importance.max,
      playSound: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        if (orderId != null && orderId.isNotEmpty) onOrderTapped?.call(orderId);
      },
    );
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kOrdersChannelId,
          kOrdersChannelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['order_id'],
    );
  }

  void _handleTap(RemoteMessage message) {
    final orderId = message.data['order_id'];
    if (orderId != null) onOrderTapped?.call(orderId);
  }

  /// Uses foundation.dart's platform checks (not dart:io's Platform) so this class stays safe
  /// to compile on every target, web included, even though the app primarily targets Android/iOS.
  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<void> registerTokenWithBackend() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb && AppConfig.fcmVapidKey.isNotEmpty ? AppConfig.fcmVapidKey : null,
      );
      if (token == null) return;
      await _api.post('/admin/device-tokens', data: {'token': token, 'platform': _platform});
    } catch (_) {
      // Non-fatal: worst case the admin just doesn't get pushes on this device until next
      // login. We don't want a notification-registration hiccup to block sign-in.
    }
  }

  Future<void> unregisterTokenFromBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _api.delete('/admin/device-tokens/$token');
    } catch (_) {
      // Best-effort on logout too.
    }
  }
}

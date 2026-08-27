import 'dart:async';

// `hide AuthProvider`: firebase_auth's own package exports a class called AuthProvider (the
// base type behind EmailAuthProvider/GoogleAuthProvider/etc.) which collides with our app's own
// AuthProvider (features/auth/auth_provider.dart, our login/session state) — hiding theirs since
// we never use it directly here, only FirebaseAuth.instance itself.
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/catalog/catalog_provider.dart';
import 'features/catalog/catalog_service.dart';
import 'features/notifications/notification_service.dart';
import 'features/orders/orders_provider.dart';
import 'features/orders/orders_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Android, the google-services Gradle plugin makes the native Firebase SDK
  // auto-initialize a "[DEFAULT]" app before Dart code ever runs — this happens
  // even on a fresh cold start, before Firebase.apps (Dart-side) knows about it.
  // Calling initializeApp() then throws core/duplicate-app; that's expected and
  // safe to ignore since the native default app is already configured correctly
  // from google-services.json.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Must be registered before runApp so Android can wake this isolate for a push that arrives
  // while the app is fully closed.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final apiClient = ApiClient(
    tokenProvider: () => FirebaseAuth.instance.currentUser?.getIdToken() ?? Future.value(null),
  );
  final notificationService = NotificationService(apiClient);

  // Paint the app immediately instead of awaiting this — on Android 13+, init() blocks on the
  // system notification-permission dialog (_messaging.requestPermission), and if that dialog is
  // slow to render (or the screen was off/locked at cold start), the user was stuck staring at
  // the bare native splash background indefinitely with nothing ever drawn. Firing it after
  // runApp() means the real UI is already visible underneath whenever that dialog does appear.
  runApp(Store8AdminApp(apiClient: apiClient, notificationService: notificationService));
  unawaited(notificationService.init());
}

class Store8AdminApp extends StatefulWidget {
  final ApiClient apiClient;
  final NotificationService notificationService;
  const Store8AdminApp({super.key, required this.apiClient, required this.notificationService});

  @override
  State<Store8AdminApp> createState() => _Store8AdminAppState();
}

class _Store8AdminAppState extends State<Store8AdminApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(widget.apiClient, widget.notificationService);
    _router = buildRouter(_authProvider);

    // A tapped notification can arrive before auth/redirect has settled (cold start). A short
    // delay lets GoRouter finish its initial /splash -> /dashboard redirect first, then we push
    // the order on top — simple and reliable for this app's scale.
    widget.notificationService.onOrderTapped = (orderId) {
      Future.delayed(const Duration(milliseconds: 350), () => _router.push('/orders/$orderId'));
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.apiClient),
        Provider.value(value: widget.notificationService),
        Provider(create: (_) => CatalogService(widget.apiClient)),
        Provider(create: (_) => OrdersService(widget.apiClient)),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (ctx) => CatalogProvider(ctx.read<CatalogService>())),
        ChangeNotifierProvider(create: (ctx) => OrdersProvider(ctx.read<OrdersService>())),
      ],
      child: MaterialApp.router(
        title: 'Store 8 Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}

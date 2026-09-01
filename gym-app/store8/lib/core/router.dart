import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/catalog/screens/brand_form_screen.dart';
import '../features/catalog/screens/category_form_screen.dart';
import '../features/catalog/screens/item_form_screen.dart';
import '../features/catalog/screens/product_form_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/offers/screens/offer_form_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';
      if (auth.status == AuthStatus.unknown) return onSplash ? null : '/splash';
      if (auth.status == AuthStatus.unauthenticated) return loggingIn ? null : '/login';
      if (auth.status == AuthStatus.authenticated && (loggingIn || onSplash)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardShell()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/catalog/category/new', builder: (context, state) => const CategoryFormScreen()),
      GoRoute(
        path: '/catalog/category/:id/edit',
        builder: (context, state) => CategoryFormScreen(categoryId: state.pathParameters['id']),
      ),
      GoRoute(path: '/catalog/brand/new', builder: (context, state) => const BrandFormScreen()),
      GoRoute(
        path: '/catalog/brand/:id/edit',
        builder: (context, state) => BrandFormScreen(brandId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/catalog/product/new',
        builder: (context, state) =>
            ProductFormScreen(initialCategoryId: state.uri.queryParameters['categoryId']),
      ),
      GoRoute(
        path: '/catalog/product/:id/edit',
        builder: (context, state) => ProductFormScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/catalog/item/new',
        builder: (context, state) => ItemFormScreen(initialProductId: state.uri.queryParameters['productId']),
      ),
      GoRoute(
        path: '/catalog/item/:id/edit',
        builder: (context, state) => ItemFormScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(path: '/offers/new', builder: (context, state) => const OfferFormScreen()),
      GoRoute(
        path: '/offers/:id/edit',
        builder: (context, state) => OfferFormScreen(offerId: state.pathParameters['id']),
      ),
    ],
  );
}

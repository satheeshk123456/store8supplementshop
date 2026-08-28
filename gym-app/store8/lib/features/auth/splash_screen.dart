import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Purely presentational — AuthProvider is already listening to Firebase's persisted auth
/// state as soon as the app starts, and GoRouter's redirect (see core/router.dart) moves on to
/// /login or /dashboard the instant that resolves. This screen just fills the gap.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 120),
            SizedBox(height: 24),
            Text(
              'STORE 8',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 6),
            Text('SUPPLEMENT SHOP', style: TextStyle(color: AppColors.textMuted, letterSpacing: 3, fontSize: 11)),
            SizedBox(height: 36),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

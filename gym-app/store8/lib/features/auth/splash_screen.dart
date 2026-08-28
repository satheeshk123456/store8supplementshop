import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Mostly presentational — AuthProvider is already listening to Firebase's persisted auth
/// state as soon as the app starts, and GoRouter's redirect (see core/router.dart) moves on to
/// /login or /dashboard the instant that resolves, which is usually near-instant. The video
/// plays muted and looping as a branded background for however long this screen happens to be
/// visible, rather than gating navigation on the video finishing — auth resolving that fast is
/// the whole point of this screen, and holding the admin up waiting for a video would work
/// against that.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.asset('assets/branding/splash_video.mp4');
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          setState(() => _controller = controller);
        })
        .catchError((_) {
          // Missing/corrupt asset, unsupported codec on this platform, etc. — fall back to the
          // plain logo splash below rather than leaving a blank screen.
          controller.dispose();
        });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final videoReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          // Dark scrim so the logo/text stay readable over whatever the video is showing.
          if (videoReady) Container(color: Colors.black.withValues(alpha: 0.45)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 120),
                const SizedBox(height: 24),
                const Text(
                  'STORE 8',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('SUPPLEMENT SHOP',
                    style: TextStyle(color: AppColors.textMuted, letterSpacing: 3, fontSize: 11)),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

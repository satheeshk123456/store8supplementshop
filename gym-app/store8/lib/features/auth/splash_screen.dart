import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';
import 'auth_provider.dart';

/// Plays the brand intro video once, with the logo plaque overlaid near the bottom. The router
/// (core/router.dart) won't leave /splash for /login or /dashboard until this screen calls
/// AuthProvider.completeIntro() — see that method's doc for why that gate exists.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  bool _videoReady = false;
  bool _videoFailed = false;

  // Splash is intentionally kept short — a brief brand flash, not the full clip. We cap it at
  // _maxSplashShow regardless of the source video's actual length (the video itself just plays
  // underneath and gets cut off when we navigate away).
  static const _maxSplashShow = Duration(seconds: 2);
  // Hard backstop: if the video never loads for any reason (bad codec, missing asset, slow
  // device), the app must not get stuck on splash forever.
  static const _maxSplashWait = Duration(seconds: 5);
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();

    _safetyTimer = Timer(_maxSplashWait, _finishIntro);

    _controller = VideoPlayerController.asset('assets/branding/splash_video.mp4')
      ..setLooping(false)
      ..setVolume(0)
      ..initialize()
          .then((_) async {
            if (!mounted) return;
            setState(() => _videoReady = true);
            await _controller.play();
            // Move on after the short cap above instead of the full clip duration, so the
            // splash feels quick regardless of how long the source video actually is.
            await Future.delayed(_maxSplashShow);
            _finishIntro();
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _videoFailed = true);
            _finishIntro();
          });
  }

  void _finishIntro() {
    _safetyTimer?.cancel();
    if (!mounted) return;
    context.read<AuthProvider>().completeIntro();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches the splash video's own background (sampled from the clip: ~#F4F4F4) so there's
      // no visible seam/border around the video box.
      backgroundColor: const Color(0xFFF4F4F4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady)
            // Small centered box, like a logo — not full-screen. Width is capped so it reads as
            // a brand mark in the middle of the screen instead of a full video background.
            Center(
              child: SizedBox(
                width: 220,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else if (_videoFailed)
            const SizedBox.shrink()
          else
            const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

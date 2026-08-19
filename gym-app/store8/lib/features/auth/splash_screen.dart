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

  // Hard backstop: if the video never loads/finishes for any reason (bad codec, missing
  // asset, slow device), the app must not get stuck on splash forever.
  static const _maxSplashWait = Duration(seconds: 12);
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
            // Wait out the full clip before letting the router move on, regardless of how
            // quickly Firebase auth resolves.
            await Future.delayed(_controller.value.duration);
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
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: Center(
              child: Image.asset('assets/branding/logo.jpeg', width: 160, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

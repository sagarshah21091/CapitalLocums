import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import 'auth/auth_session.dart';
import 'brand_colors.dart';

/// Loops the Lottie splash, hydrates session, then [GoRouter] redirect runs.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.splashDuration = const Duration(seconds: 4),
  });

  final Duration splashDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _redirectTimer;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(widget.splashDuration, _finishSplash);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateSession());
  }

  Future<void> _hydrateSession() async {
    if (_hydrated) return;
    await ref.read(authSessionProvider.notifier).hydrate();
    if (mounted) {
      setState(() => _hydrated = true);
    }
  }

  Future<void> _finishSplash() async {
    if (!mounted) return;
    await _hydrateSession();
    // Navigation is handled by GoRouter redirect after session is known.
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Capital Locums',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: BrandColors.locumsGreen,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: size.width * 0.72,
                  height: size.height * 0.36,
                  child: Lottie.asset(
                    'assets/lottie/splash.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Brand colors taken from Bodymovin fills in [assets/lottie/splash.json].
abstract final class BrandColors {
  BrandColors._();

  /// Sage / mint green (fills ≈ rgb 210, 233, 149).
  static const Color locumsMint = Color(0xFFD2E995);

  /// Richer green from the same animation (fills ≈ rgb 49, 170, 71); better on light surfaces.
  static const Color locumsGreen = Color(0xFF31AA47);
}

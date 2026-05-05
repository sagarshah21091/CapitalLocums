import 'package:flutter/material.dart';

import 'brand_colors.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capital Locums',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: BrandColors.locumsGreen),
        useMaterial3: true,
      ),
      home: const SplashScreen(
        next: LoginScreen(),
      ),
    );
  }
}

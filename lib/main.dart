import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brand_colors.dart';
import 'router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Capital Locums',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: BrandColors.locumsGreen),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

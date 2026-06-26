import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_version.dart';
import 'brand_colors.dart';
import 'env/app_env.dart';
import 'router/app_router.dart';

void _configureAndroidPhotoPicker() {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureAndroidPhotoPicker();

  await AppEnv.load();
  await initAppVersion();

  // Opens the SharedPreferences platform channel before first login save.
  // Avoids pigeon channel errors when plugins initialize too late on some targets.
  try {
    await SharedPreferences.getInstance();
  } catch (e, st) {
    debugPrint('SharedPreferences warmup failed (token save may fail): $e');
    debugPrint('$st');
  }

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home_page.dart';
import '../login_screen.dart';
import '../splash_screen.dart';

/// Path segments for [GoRouter]; use with [context.go] / [context.push].
abstract final class AppRoute {
  AppRoute._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.splash,
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoute.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoute.home,
        builder: (BuildContext context, GoRouterState state) {
          return const MyHomePage(title: 'Capital Locums');
        },
      ),
    ],
  );
});

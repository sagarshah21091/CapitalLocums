import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../book/book_now_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../forgot_password_screen.dart';
import '../login_screen.dart';
import '../profile/profile_screen.dart';
import '../register/register_screen.dart';
import '../settings/settings_screen.dart';
import '../shell/main_shell_screen.dart';
import '../splash_screen.dart';

/// Path segments for [GoRouter]; use with [context.go] / [context.push].
abstract final class AppRoute {
  AppRoute._();

  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const register = '/register';

  /// Main app shell (bottom tabs); default tab is [dashboard].
  static const dashboard = '/dashboard';
  static const book = '/book';
  static const settings = '/settings';

  static const profile = '/profile';
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
        path: AppRoute.forgotPassword,
        builder: (BuildContext context, GoRouterState state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: AppRoute.register,
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.dashboard,
                builder: (BuildContext context, GoRouterState state) {
                  return const DashboardScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.book,
                builder: (BuildContext context, GoRouterState state) {
                  return const BookNowScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.settings,
                builder: (BuildContext context, GoRouterState state) {
                  return const SettingsScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.profile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileScreen();
        },
      ),
    ],
  );
});

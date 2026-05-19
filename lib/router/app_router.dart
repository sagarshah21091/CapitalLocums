import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_session.dart';
import '../book/book_now_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../forgot_password_screen.dart';
import '../login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../profile/profile_screen.dart';
import '../register/register_screen.dart';
import '../settings/settings_screen.dart';
import '../shell/main_shell_screen.dart';
import '../shifts/shift_detail_screen.dart';
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

  static const myBookings = '/my-bookings';

  static const shiftDetail = '/shifts/:shiftId';

  static String shiftDetailPath(int shiftId, {bool isBooked = false}) {
    final booked = isBooked ? '1' : '0';
    return '/shifts/$shiftId?is_booked=$booked';
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

bool _isPublicAuthRoute(String location) {
  return location == AppRoute.login ||
      location == AppRoute.register ||
      location.startsWith(AppRoute.forgotPassword);
}

String? _authRedirect(AuthSessionStatus status, String location) {
  if (status == AuthSessionStatus.unknown) {
    return location == AppRoute.splash ? null : AppRoute.splash;
  }

  final loggedIn = status == AuthSessionStatus.authenticated;

  if (loggedIn) {
    if (location == AppRoute.splash || location == AppRoute.login) {
      return AppRoute.dashboard;
    }
    return null;
  }

  // Not logged in
  if (location == AppRoute.splash) {
    return AppRoute.login;
  }
  if (_isPublicAuthRoute(location)) {
    return null;
  }
  return AppRoute.login;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(refreshListenable.dispose);

  ref.listen(authSessionProvider, (_, _) {
    refreshListenable.value++;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.splash,
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final status = ref.read(authSessionProvider);
      return _authRedirect(status, state.matchedLocation);
    },
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
      GoRoute(
        path: AppRoute.myBookings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const MyBookingsScreen();
        },
      ),
      GoRoute(
        path: AppRoute.shiftDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final id = int.tryParse(state.pathParameters['shiftId'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid shift')),
            );
          }
          final isBooked = state.uri.queryParameters['is_booked'] == '1';
          return ShiftDetailScreen(
            shiftId: id,
            initialIsBooked: isBooked,
          );
        },
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_shell_page.dart';
import 'startup_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/histories/presentation/histories_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/territories/presentation/map_page.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/runs/presentation/run_summary_page.dart';
import '../features/leaderboard/presentation/leaderboard_page.dart';

final startupDelayPassedProvider = StateProvider<bool>((ref) => false);

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final startupDelayPassed = ref.watch(startupDelayPassedProvider);
  return GoRouter(
    initialLocation: '/startup',
    redirect: (context, state) {
      final onStartup = state.matchedLocation == '/startup';
      final loggingIn = state.matchedLocation == '/login';

      if (!startupDelayPassed) {
        return onStartup ? null : '/startup';
      }

      if (auth.status == AuthStatus.unknown) {
        return onStartup ? null : '/startup';
      }

      final isAuthed = auth.status == AuthStatus.authenticated;
      if (onStartup) return isAuthed ? '/map' : '/login';
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/map';
      return null;
    },
    routes: [
      GoRoute(path: '/startup', builder: (context, state) => const StartupPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/histories',
                builder: (context, state) => const HistoriesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/run-summary',
        builder: (context, state) => const RunSummaryPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardPage(),
      ),
    ],
  );
});

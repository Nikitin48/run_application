import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_shell_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/territories/presentation/map_page.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/runs/presentation/run_summary_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (auth.status == AuthStatus.unknown) return null;

      final isAuthed = auth.status == AuthStatus.authenticated;
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/map';
      return null;
    },
    routes: [
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
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../responsive/responsive_shell.dart';

/// Rute utama aplikasi.
class AppRoutes {
  const AppRoutes._();
  static const login = '/login';
  static const dashboard = '/dashboard';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifier yang memicu router evaluasi ulang guard saat sesi auth berubah.
class _RouterRefresh extends ChangeNotifier {
  void poke() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen(authProvider, (_, __) => refresh.poke());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final signedIn = auth is AuthSignedIn;
      final goingTo = state.matchedLocation;
      // Guard route: belum login -> paksa ke halaman login, dan sebaliknya.
      if (!signedIn && goingTo != AppRoutes.login) return AppRoutes.login;
      if (signedIn && goingTo == AppRoutes.login) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
        ],
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/categories/presentation/category_page.dart';
import '../../features/customers/presentation/customer_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/products/presentation/product_page.dart';
import '../../features/cash/presentation/cash_page.dart';
import '../../features/sales/presentation/sale_page.dart';
import '../../features/pos/presentation/pos_page.dart';
import '../../features/purchases/presentation/purchase_page.dart';
import '../../features/suppliers/presentation/supplier_page.dart';
import '../../features/expenses/presentation/expenses_page.dart';
import '../../features/income/presentation/income_page.dart';
import '../responsive/responsive_shell.dart';

/// Rute utama aplikasi.
class AppRoutes {
  const AppRoutes._();
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const categories = '/categories';
  static const suppliers = '/suppliers';
  static const customers = '/customers';
  static const inventory = '/inventory';
  static const purchases = '/purchases';
  static const pos = '/pos';
  static const sales = '/sales';
  static const cash = '/cash';
  static const expenses = '/expenses';
  static const income = '/income';
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
          GoRoute(
            path: AppRoutes.products,
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: AppRoutes.categories,
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: AppRoutes.suppliers,
            builder: (context, state) => const SuppliersPage(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (context, state) => const CustomersPage(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: AppRoutes.purchases,
            builder: (context, state) => const PurchasesPage(),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (context, state) => const PosPage(),
          ),
          GoRoute(
            path: AppRoutes.sales,
            builder: (context, state) => const SalesPage(),
          ),
          GoRoute(
            path: AppRoutes.cash,
            builder: (context, state) => const CashPage(),
          ),
          GoRoute(
            path: AppRoutes.expenses,
            builder: (context, state) => const ExpensesPage(),
          ),
          GoRoute(
            path: AppRoutes.income,
            builder: (context, state) => const IncomePage(),
          ),
        ],
      ),
    ],
  );
});

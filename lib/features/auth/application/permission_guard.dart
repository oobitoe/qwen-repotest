import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/states.dart';
import '../application/auth_controller.dart';

/// Provider untuk memeriksa izin fitur berdasarkan role aktif.
final permissionGuardProvider = Provider<PermissionGuard>((ref) {
  final role = ref.watch(currentRoleProvider);
  return PermissionGuard(role);
});

/// Helper class untuk memeriksa izin.
class PermissionGuard {
  const PermissionGuard(this.role);

  final UserRole? role;

  /// Cek apakah role memiliki izin tertentu.
  bool hasPermission(String permission) {
    if (role == null) return false;
    return roleHasPermission(role!, permission);
  }

  /// Cek multiple izin (semua harus terpenuhi).
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every(hasPermission);
  }

  /// Cek multiple izin (minimal satu terpenuhi).
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any(hasPermission);
  }
}

/// Widget yang menampilkan konten hanya jika user memiliki izin.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final String permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(permissionGuardProvider);
    if (guard.hasPermission(permission)) {
      return child;
    }
    return fallback ??
        const ErrorState(
          message: 'Anda tidak memiliki akses ke fitur ini',
          onRetry: null,
          icon: Icons.lock_outline_rounded,
        );
  }
}

/// Widget yang menampilkan konten berbeda berdasarkan izin.
class PermissionSwitch extends ConsumerWidget {
  const PermissionSwitch({
    super.key,
    required this.permission,
    required this.allowedChild,
    this.deniedChild,
  });

  final String permission;
  final Widget allowedChild;
  final Widget? deniedChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guard = ref.watch(permissionGuardProvider);
    if (guard.hasPermission(permission)) {
      return allowedChild;
    }
    return deniedChild ??
        const SizedBox.shrink();
  }
}

/// Mixin untuk screen yang butuh permission check.
mixin PermissionRequiredMixin<T extends StatefulWidget> on State<T> {
  String get requiredPermission;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermission();
  }

  void _checkPermission() {
    final guard = PermissionGuard(currentRoleProvider.read(ProviderContainer()));
    if (!guard.hasPermission(requiredPermission)) {
      // Navigate to dashboard or show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      });
    }
  }
}

/// Extension untuk memudahkan cek permission di widget.
extension PermissionExtension on BuildContext {
  bool hasPermission(String permission, {UserRole? role}) {
    final guard = PermissionGuard(role);
    return guard.hasPermission(permission);
  }
}

/// Permission constants untuk konsistensi.
class AppPermissions {
  const AppPermissions._();

  // Dashboard
  static const dashboardView = 'dashboard.view';

  // Products
  static const productsView = 'products.view';
  static const productsManage = 'products.manage';

  // Categories
  static const categoriesView = 'categories.view';
  static const categoriesManage = 'categories.manage';

  // Inventory/Stock
  static const stockManage = 'stock.manage';
  static const stockView = 'stock.view';

  // POS
  static const posUse = 'pos.use';

  // Sales
  static const salesView = 'sales.view';
  static const salesManage = 'sales.manage';

  // Purchases
  static const purchasesView = 'purchases.view';
  static const purchasesManage = 'purchases.manage';

  // Suppliers
  static const suppliersView = 'suppliers.view';
  static const suppliersManage = 'suppliers.manage';

  // Customers
  static const customersView = 'customers.view';
  static const customersManage = 'customers.manage';

  // Expenses
  static const expensesView = 'expenses.view';
  static const expensesManage = 'expenses.manage';

  // Income
  static const incomeView = 'income.view';
  static const incomeManage = 'income.manage';

  // Debts
  static const debtsView = 'debts.view';
  static const debtsManage = 'debts.manage';

  // Reports
  static const reportsView = 'reports.view';
  static const reportsExport = 'reports.export';

  // Cash Management
  static const cashView = 'cash.view';
  static const cashManage = 'cash.manage';

  // Users
  static const usersView = 'users.view';
  static const usersManage = 'users.manage';

  // Settings
  static const settingsView = 'settings.view';
  static const settingsManage = 'settings.manage';

  // Audit Log
  static const auditLogView = 'audit_log.view';
}
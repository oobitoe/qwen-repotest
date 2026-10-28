import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_top_bar.dart';
import 'responsive_layout.dart';

/// State sidebar: true = diciutkan (tablet/desktop). Dipertahankan selama sesi aplikasi.
class SidebarController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final sidebarCollapsedProvider =
    NotifierProvider<SidebarController, bool>(SidebarController.new);

class NavItem {
  const NavItem(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Destinasi navigasi utama. Fase berikutnya menambah rute sesuai PRD.
const appNavItems = <NavItem>[
  NavItem('/dashboard', 'dashboard', AppIcons.dashboardOutlined,
      AppIcons.dashboardRounded),
  NavItem('/products', 'products', AppIcons.inventory2Rounded,
      AppIcons.inventory2Rounded),
  NavItem('/categories', 'categories', AppIcons.categoryRounded,
      AppIcons.categoryRounded),
  NavItem('/suppliers', 'suppliers', AppIcons.storefrontRounded,
      AppIcons.storefrontRounded),
  NavItem('/customers', 'customers', AppIcons.shoppingBagRounded,
      AppIcons.shoppingBagRounded),
  NavItem('/inventory', 'inventory', AppIcons.inventory2Rounded,
      AppIcons.inventory2Rounded),
  NavItem('/purchases', 'purchases', AppIcons.shoppingCartRounded,
      AppIcons.shoppingCartRounded),
  NavItem('/pos', 'pos', AppIcons.checkoutRounded, AppIcons.checkoutRounded),
  NavItem('/sales', 'sales', AppIcons.receiptLongRounded,
      AppIcons.receiptLongRounded),
  NavItem('/cash', 'cash', AppIcons.accountBalanceRounded,
      AppIcons.accountBalanceRounded),
  NavItem('/expenses', 'expenses', AppIcons.receiptLongRounded,
      AppIcons.receiptLongRounded),
  NavItem('/income', 'income', AppIcons.savingsRounded,
      AppIcons.savingsRounded),
  NavItem('/debts', 'debts', AppIcons.accountBalanceRounded,
      AppIcons.accountBalanceRounded),
  NavItem('/reports', 'reports', AppIcons.analyticsRounded,
      AppIcons.analyticsRounded),
  NavItem('/audit-log', 'auditLog', AppIcons.historyRounded,
      AppIcons.historyRounded),
  NavItem('/settings', 'settings', AppIcons.settingsRounded,
      AppIcons.settingsRounded),
];

/// Resolve label tujuan navigasi ke string terlokalisasi.
String _navLabel(AppLocalizations l10n, String key) => switch (key) {
      'dashboard' => l10n.dashboard,
      'products' => l10n.products,
      'categories' => l10n.categories,
      'suppliers' => l10n.suppliers,
      'customers' => l10n.customers,
      'inventory' => l10n.inventory,
      'purchases' => l10n.purchases,
      'pos' => l10n.pos,
      'sales' => l10n.sales,
      'cash' => l10n.cashRegister,
      'expenses' => l10n.expenses,
      'income' => l10n.income,
      'debts' => l10n.debts,
      'reports' => l10n.reports,
      'auditLog' => l10n.auditLog,
      'settings' => l10n.settings,
      _ => key,
    };

/// Resolve judul halaman dari lokasi route saat ini.
String _pageTitle(String location, AppLocalizations l10n) {
  switch (location) {
    case '/dashboard':
      return l10n.dashboard;
    case '/products':
      return l10n.products;
    case '/categories':
      return l10n.categories;
    case '/suppliers':
      return l10n.suppliers;
    case '/customers':
      return l10n.customers;
    case '/inventory':
      return l10n.inventory;
    case '/purchases':
      return l10n.purchases;
    case '/pos':
      return l10n.pos;
    case '/sales':
      return l10n.sales;
    case '/cash':
      return l10n.cashRegister;
    case '/expenses':
      return l10n.expenses;
    case '/income':
      return l10n.income;
    case '/debts':
      return l10n.debts;
    case '/reports':
      return l10n.reports;
    case '/audit-log':
      return l10n.auditLog;
    case '/settings':
      return l10n.settings;
    case '/login':
      return l10n.appDisplayName;
    default:
      return l10n.appDisplayName;
  }
}

/// Shell responsif dengan animasi:
/// - Mobile: hamburger menu di topbar buka/tutup drawer sidebar.
/// - Tablet: sidebar collapsed (hanya icon, teks jadi tooltip), tidak ada hamburger.
/// - Desktop: sidebar expanded.
class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget child;

  static int _indexFor(String location) {
    final i = appNavItems.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFor(location);
    final l10n = AppLocalizations.of(context)!;
    final title = _pageTitle(location, l10n);
    final isMobile = context.isMobile;

    if (isMobile) {
      return Scaffold(
        appBar: _TopBarWrapper(title: title),
        drawer: _MobileDrawer(
          currentIndex: currentIndex,
          l10n: l10n,
        ),
        body: child,
      );
    }

    // Tablet selalu collapsed (hanya icon, teks jadi tooltip), desktop mengikuti provider.
    final collapsed = context.isTablet ? true : ref.watch(sidebarCollapsedProvider);

    return _SidebarShell(
      currentIndex: currentIndex,
      l10n: l10n,
      child: child,
      title: title,
      collapsed: collapsed,
      onToggle: () => ref
          .read(sidebarCollapsedProvider.notifier)
          .toggle(),
    );
  }
}

/// Wrapper agar [AppTopBar] punya konteks Scaffold (untuk [Scaffold.of] di tombol menu mobile).
class _TopBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  const _TopBarWrapper({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => AppTopBar(
        title: title,
        onMenuTap: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}

/// Drawer sidebar khusus mobile (muncul dari kiri saat hamburger ditekan).
class _MobileDrawer extends ConsumerWidget {
  const _MobileDrawer({
    required this.currentIndex,
    required this.l10n,
  });

  final int currentIndex;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(AppIcons.storefrontRounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.appDisplayName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: ListView.separated(
                itemCount: appNavItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = appNavItems[index];
                  final isSelected = index == currentIndex;
                  return _NavItemTile(
                    item: item,
                    isSelected: isSelected,
                    collapsed: false,
                    l10n: l10n,
                    onTap: () {
                      context.go(item.path);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              l10n.appVersion,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarShell extends ConsumerWidget {
  const _SidebarShell({
    required this.currentIndex,
    required this.child,
    required this.l10n,
    required this.title,
    required this.collapsed,
    required this.onToggle,
  });

  final int currentIndex;
  final Widget child;
  final AppLocalizations l10n;
  final String title;
  final bool collapsed;
  final VoidCallback onToggle;

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 84;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = collapsed ? _collapsedWidth : _expandedWidth;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar full height (dari atas sampai bawah)
          // Tablet: collapsed (hanya icon, teks jadi tooltip)
          // Desktop: expanded
          AnimatedContainer(
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            width: width,
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ]),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(AppIcons.storefrontRounded,
                            color: Colors.white, size: 22),
                      ),
                      if (!collapsed)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: AppSpacing.md),
                            child: Text(
                              l10n.appDisplayName,
                              overflow: TextOverflow.clip,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Navigasi menggunakan ListView untuk mendukung scroll
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: ListView.separated(
                      itemCount: appNavItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = appNavItems[index];
                        final isSelected = index == currentIndex;
                        return _NavItemTile(
                          item: item,
                          isSelected: isSelected,
                          collapsed: collapsed,
                          l10n: l10n,
                          onTap: () => context.go(item.path),
                        );
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!collapsed)
                        Text(l10n.appVersion,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      IconButton.filledTonal(
                        tooltip: collapsed
                            ? l10n.tooltipOpenSidebar
                            : l10n.tooltipCollapseSidebar,
                        onPressed: onToggle,
                        icon: AnimatedRotation(
                          turns: collapsed ? 0.5 : 0,
                          duration: AppDurations.normal,
                          child: const Icon(AppIcons.chevronLeftRounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1,
              color: theme.colorScheme.outlineVariant),
          // TopBar di kanan sidebar, di atas konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: AppTopBar(title: title),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.l10n,
    required this.onTap,
  });

  final NavItem item;
  final bool isSelected;
  final bool collapsed;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: collapsed
              ? Tooltip(
                  message: _navLabel(l10n, item.label),
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: color,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _navLabel(l10n, item.label),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Halaman placeholder untuk rute yang belum dibangun (Fase 3+).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.constructionRounded,
                size: 48, color: AppTheme.warning),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.comingSoon(title),
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

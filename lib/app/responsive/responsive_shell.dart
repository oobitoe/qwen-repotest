import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import 'responsive_layout.dart';

/// State sidebar: true = diciutkan. Dipertahankan selama sesi aplikasi.
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
];

/// Resolve label tujuan navigasi ke string terlokalisasi.
String _navLabel(AppLocalizations l10n, String key) => switch (key) {
      'dashboard' => l10n.dashboard,
      _ => key,
    };

/// Shell responsif dengan animasi:
/// - Mobile: NavigationBar di bawah.
/// - Tablet/Desktop: sidebar yang bisa diciutkan (toggle animasi lebar).
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

    if (context.isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) =>
              context.go(appNavItems[i].path),
          destinations: [
            for (final d in appNavItems)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: _navLabel(l10n, d.label),
              ),
          ],
        ),
      );
    }
    return _SidebarShell(currentIndex: currentIndex, l10n: l10n, child: child);
  }
}

class _SidebarShell extends ConsumerWidget {
  const _SidebarShell({
    required this.currentIndex,
    required this.child,
    required this.l10n,
  });

  final int currentIndex;
  final Widget child;
  final AppLocalizations l10n;

  static const double _expandedWidth = 240;
  static const double _collapsedWidth = 84;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final theme = Theme.of(context);
    final width = collapsed ? _collapsedWidth : _expandedWidth;

    return Scaffold(
      body: Row(
        children: [
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
                      Expanded(
                        child: AnimatedSize(
                          duration: AppDurations.normal,
                          alignment: Alignment.centerLeft,
                          child: collapsed
                              ? const SizedBox(width: 1)
                              : Padding(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    child: NavigationRail(
                      extended: !collapsed,
                      selectedIndex: currentIndex,
                      onDestinationSelected: (i) =>
                          context.go(appNavItems[i].path),
                      labelType: collapsed
                          ? NavigationRailLabelType.all
                          : null,
                      indicatorColor:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                      destinations: [
                        for (final d in appNavItems)
                          NavigationRailDestination(
                            icon: _AnimIcon(
                              icon: collapsed ? d.selectedIcon : d.icon,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            selectedIcon: _AnimIcon(
                              icon: d.selectedIcon,
                              color: theme.colorScheme.primary,
                            ),
                            label: Text(_navLabel(l10n, d.label)),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!collapsed)
                        Text(l10n.appVersion,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      IconButton.filledTonal(
                        tooltip: collapsed
                            ? l10n.tooltipOpenSidebar
                            : l10n.tooltipCollapseSidebar,
                        onPressed: () => ref
                            .read(sidebarCollapsedProvider.notifier)
                            .toggle(),
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
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AnimIcon extends StatelessWidget {
  const _AnimIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: AppDurations.normal,
        builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
        child: Icon(icon, color: color),
      );
}

/// Halaman placeholder untuk rute yang belum dibangun (Fase 3+).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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

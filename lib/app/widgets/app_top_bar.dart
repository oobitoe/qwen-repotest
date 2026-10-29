import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/core_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../core/database/sync_engine.dart';

/// Dedicated topbar yang di-share oleh semua halaman melalui [ResponsiveShell].
///
/// Hanya [title] yang berubah sesuai halaman aktif. Aksi kanan (sync, logout)
/// konsisten di seluruh aplikasi.
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onMenuTap});

  final String title;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sync = ref.watch(syncStatusProvider);
    final role = ref.watch(currentRoleProvider);
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: isMobile && onMenuTap != null
            ? IconButton(
                tooltip: 'Menu',
                onPressed: onMenuTap,
                icon: const Icon(menu, size: 18),
              )
          : null,
        leadingWidth: (isMobile && onMenuTap != null) ? 56 : 0,
        titleSpacing: 0.0,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
            ),
          ),
        ),
        actions: const [],
      ),
    );
  }
}

const IconData menu = Icons.menu_rounded;

/// Chip sapaan sesuai role (hanya muncul di layar tablet/desktop).
class _GreetingChip extends StatelessWidget {
  const _GreetingChip({required this.role, required this.l10n});

  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 11
        ? l10n.greetingMorning
        : hour < 15
            ? l10n.greetingAfternoon
            : hour < 19
                ? l10n.greetingEvening
                : l10n.greetingNight;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(l10n.greetingRole(greet, role),
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// Badge status sinkronisasi di topbar.
class _SyncBadge extends ConsumerWidget {
  const _SyncBadge({required this.status, required this.l10n});

  final AsyncValue<SyncStatus> status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = status.valueOrNull;
    final (icon, color) = switch (s?.phase) {
      SyncPhase.offline => (AppIcons.cloudOffRounded, AppTheme.warning),
      SyncPhase.syncing => (AppIcons.syncRounded, AppTheme.info),
      SyncPhase.error => (AppIcons.errorOutlineRounded, AppTheme.error),
      _ => (AppIcons.cloudDoneRounded, AppTheme.success),
    };
    return Tooltip(
      message: switch (s?.phase) {
        SyncPhase.offline => l10n.offlineSaved,
        SyncPhase.syncing => 'Sinkronisasi berjalan',
        SyncPhase.error => l10n.syncInterrupted,
        _ => 'Terhubung & tersinkron',
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

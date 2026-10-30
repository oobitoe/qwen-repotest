import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/providers/core_providers.dart';
import '../../shared/providers/user_profile_provider.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../core/database/sync_engine.dart';

const IconData _menu = Icons.menu_rounded;

/// Dedicated topbar yang di-share oleh semua halaman melalui [ResponsiveShell].
///
/// Layout (anti-overflow):
/// - Kiri  : tombol menu (mobile).
/// - Tengah: judul halaman (Expanded → tak pernah overflow).
/// - Kanan : greeting chip (tablet/desktop) + ikon sync/offline +
///           badge (saat offline & belum ter-sync) + tombol profil bulat
///           membuka dropdown (nama, email, role, logout).
class AppTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onMenuTap});

  final String title;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _agoString(DateTime? lastSync, AppLocalizations l10n) {
    if (lastSync == null) return '';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 5) return l10n.agoJustNow;
    if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
    return l10n.agoHours(diff.inHours);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncAsync = ref.watch(syncStatusProvider);
    final role = ref.watch(currentRoleProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    final syncStatus = syncAsync.valueOrNull;
    final phase = syncStatus?.phase ?? SyncPhase.idle;
    final isOffline = phase == SyncPhase.offline;
    final pendingCount = syncStatus?.pendingCount ?? 0;

    final (iconData, iconColor) = switch (phase) {
      SyncPhase.offline => (AppIcons.cloudOffRounded, AppTheme.warning),
      SyncPhase.syncing => (AppIcons.syncRounded, AppTheme.info),
      SyncPhase.error => (AppIcons.errorOutlineRounded, AppTheme.error),
      _ => (AppIcons.cloudDoneRounded, AppTheme.success),
    };

    final syncTooltip = switch (phase) {
      SyncPhase.offline => l10n.offlinePending(pendingCount),
      SyncPhase.syncing => l10n.syncing(pendingCount),
      SyncPhase.error => l10n.syncError(syncStatus?.message ?? ''),
      _ => l10n.syncSynced(_agoString(syncStatus?.lastSyncAt, l10n)),
    };

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.circular(AppRadius.md),
      ),
      child: Container(
        height: kToolbarHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Kiri: tombol menu (mobile) ---
            if (isMobile && onMenuTap != null) ...[
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenuTap,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(_menu, size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            // Padding kiri agar judul tidak mentok ke sisi (mobile sidebar)
            if (!isMobile) const SizedBox(width: AppSpacing.xs),

            // --- Tengah: judul (Expanded agar fleksibel & tidak overflow) ---
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),

            // --- Greeting chip (tablet/desktop) — menyampingkan ikon sync ---
            if (!isMobile) ...[
              _GreetingChip(role: role, l10n: l10n),
              const SizedBox(width: AppSpacing.sm),
            ],

            // --- Kanan: ikon sync/offline + badge ---
            Tooltip(
              message: syncTooltip,
              child: _SyncIconWithBadge(
                icon: iconData,
                color: iconColor,
                phase: phase,
                isOffline: isOffline,
                pendingCount: pendingCount,
                badgeColor: scheme.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // --- Kanan: tombol profil (diberi padding pinggir kanan) ---
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _UserProfileButton(
                ref: ref,
                l10n: l10n,
                profile: profileAsync,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon sinkronisasi berputar saat syncing, dengan badge jumlah
/// data yang belum ter-sync saat offline.
class _SyncIconWithBadge extends StatefulWidget {
  const _SyncIconWithBadge({
    required this.icon,
    required this.color,
    required this.phase,
    required this.isOffline,
    required this.pendingCount,
    required this.badgeColor,
  });

  final IconData icon;
  final Color color;
  final SyncPhase phase;
  final bool isOffline;
  final int pendingCount;
  final Color badgeColor;

  @override
  State<_SyncIconWithBadge> createState() => _SyncIconWithBadgeState();
}

class _SyncIconWithBadgeState extends State<_SyncIconWithBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController.unbounded(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _SyncIconWithBadge old) {
    super.didUpdateWidget(old);
    // Mulai/jatikan animasi berputar hanya saat phase berubah.
    if (widget.phase == SyncPhase.syncing && !_anim.isAnimating) {
      _anim.repeat(period: const Duration(seconds: 2));
    } else if (widget.phase != SyncPhase.syncing && _anim.isAnimating) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RotationTransition(
              turns: _anim,
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
          ),
          if (widget.isOffline && widget.pendingCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Badge(
                backgroundColor: widget.badgeColor,
                label: Text(
                  '${widget.pendingCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip sapaan sesuai role (hanya muncul di layar tablet/desktop).
class _GreetingChip extends StatelessWidget {
  const _GreetingChip({required this.role, required this.l10n});

  final UserRole? role;
  final AppLocalizations l10n;

  static String _roleLabel(UserRole? role) => switch (role) {
        UserRole.owner => 'Owner',
        UserRole.admin => 'Admin',
        UserRole.manager => 'Manager',
        UserRole.kasir => 'Kasir',
        UserRole.staffGudang => 'Staff Gudang',
        null => 'Owner',
      };

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
    final roleLabel = _roleLabel(role);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Text(
        l10n.greetingRole(greet, roleLabel),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

/// Tombol profil pengguna bulat yang membuka dropdown dengan info + logout.
class _UserProfileButton extends StatelessWidget {
  const _UserProfileButton({
    required this.ref,
    required this.l10n,
    required this.profile,
  });

  final WidgetRef ref;
  final AppLocalizations l10n;
  final AsyncValue<UserProfile> profile;

  static const _actionLogout = 'logout';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = profile.valueOrNull;
    final name = p?.fullName ?? 'Owner';
    final email = p?.email ?? 'offline@local';
    final roleLabel = p?.roleLabel ?? 'Owner';

    return PopupMenuButton<String>(
      tooltip: l10n.user,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      onSelected: (value) {
        if (value == _actionLogout) {
          ref.read(authProvider.notifier).signOut();
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(AppIcons.personRounded, size: 18),
      ),
      itemBuilder: (context) => [
        // Informasi pengguna (tidak dapat dipilih)
        PopupMenuItem<String>(
          enabled: false,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.role}: $roleLabel',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: _actionLogout,
          child: Row(
            children: [
              Icon(AppIcons.logout, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.logout),
            ],
          ),
        ),
      ],
    );
  }
}

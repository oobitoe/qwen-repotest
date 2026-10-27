import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../app/theme/theme_presets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/providers/core_providers.dart';

/// Halaman pengaturan aplikasi.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preset = ref.watch(themePresetProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Theme Preset Section
          _SectionHeader(title: l10n.themePreset, subtitle: l10n.themePresetSubtitle),
          const SizedBox(height: AppSpacing.md),
          _ThemePresetGrid(
            currentPreset: preset,
            onSelect: (newPreset) => ref.read(themePresetProvider.notifier).state = newPreset,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Theme Mode Section
          _SectionHeader(title: l10n.themeMode, subtitle: l10n.themeModeSubtitle),
          const SizedBox(height: AppSpacing.md),
          _ThemeModeSelector(
            currentMode: themeMode,
            onChanged: (mode) => ref.read(themeModeProvider.notifier).state = mode,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Language Section
          _SectionHeader(title: l10n.language, subtitle: l10n.languageSubtitle),
          const SizedBox(height: AppSpacing.md),
          _LanguageSelector(),
          const SizedBox(height: AppSpacing.xl),

          // Sync Section
          _SectionHeader(title: l10n.sync, subtitle: l10n.syncSubtitle),
          const SizedBox(height: AppSpacing.md),
          _SyncSettings(),
          const SizedBox(height: AppSpacing.xl),

          // About Section
          _SectionHeader(title: l10n.about, subtitle: l10n.aboutSubtitle),
          const SizedBox(height: AppSpacing.md),
          _AboutCard(appName: l10n.appDisplayName),
        ],
      ),
    );
  }
}

/// Header section dengan judul dan subtitle.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Grid pemilihan preset tema.
class _ThemePresetGrid extends ConsumerWidget {
  const _ThemePresetGrid({required this.currentPreset, required this.onSelect});

  final ThemePreset currentPreset;
  final ValueChanged<ThemePreset> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = AppThemePresets.presets;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final preset in presets)
          _ThemePresetCard(
            preset: preset,
            isSelected: preset.id == currentPreset.id,
            onTap: () => onSelect(preset),
          ),
      ],
    );
  }
}

/// Kartu preset tema.
class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final ThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = ColorScheme.fromSeed(seedColor: preset.seedColor, brightness: Brightness.light);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: Curves.easeOut,
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerLow,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color swatches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ColorDot(color: preset.seedColor, label: 'Primary', isSelected: isSelected),
                _ColorDot(color: preset.secondary, label: 'Secondary', isSelected: isSelected),
                _ColorDot(color: preset.tertiary, label: 'Tertiary', isSelected: isSelected),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Name & description
            Text(
              preset.name,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              preset.description,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Check indicator
            if (isSelected)
              Row(
                children: [
                  Icon(AppIcons.checkCircleOutlineRounded, size: 16, color: scheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Aktif',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Titik warna kecil untuk preview.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.label,
    required this.isSelected,
  });

  final Color color;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

/// Selector mode tema (light/dark/system).
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(l10n.themeLight),
          icon: const Icon(AppIcons.wbSunnyRounded),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(l10n.themeDark),
          icon: const Icon(AppIcons.nightlightRoundRounded),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(l10n.themeSystem),
          icon: const Icon(AppIcons.settingsSystemDaydreamRounded),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

/// Selector bahasa.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // TODO: Implement language provider
    const currentLocale = 'id';

    return Column(
      children: [
        _LanguageTile(
          locale: 'id',
          name: l10n.indonesian,
          isSelected: currentLocale == 'id',
          onTap: () {
            // TODO: Change locale
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.languageChanged(l10n.indonesian))),
            );
          },
        ),
        _LanguageTile(
          locale: 'en',
          name: l10n.english,
          isSelected: currentLocale == 'en',
          onTap: () {
            // TODO: Change locale
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.languageChanged(l10n.english))),
            );
          },
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String locale;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      tileColor: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : theme.colorScheme.surfaceContainerLow,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          isSelected ? AppIcons.checkRounded : AppIcons.languageRounded,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      trailing: isSelected
          ? Icon(AppIcons.checkRounded, color: theme.colorScheme.primary)
          : null,
    );
  }
}

/// Pengaturan sinkronisasi.
class _SyncSettings extends ConsumerWidget {
  const _SyncSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          onTap: () => ref.read(syncEngineProvider).syncNow(),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          tileColor: theme.colorScheme.surfaceContainerLow,
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(AppIcons.sync, color: theme.colorScheme.primary),
          ),
          title: Text(l10n.manualSync, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.manualSyncDesc, style: theme.textTheme.bodySmall),
          trailing: const Icon(AppIcons.chevronRightRounded),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          onTap: () {
            // TODO: Show sync queue
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          tileColor: theme.colorScheme.surfaceContainerLow,
          leading: CircleAvatar(
            backgroundColor: AppTheme.info.withValues(alpha: 0.15),
            child: Icon(AppIcons.queueRounded, color: AppTheme.info),
          ),
          title: Text(l10n.syncQueue, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(l10n.syncQueueDesc, style: theme.textTheme.bodySmall),
          trailing: const Icon(AppIcons.chevronRightRounded),
        ),
      ],
    );
  }
}

/// Kartu tentang aplikasi.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ]),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(AppIcons.storefrontRounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(l10n.version('0.1.0'), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.aboutDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.techStack, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tech in ['Flutter', 'Drift', 'Riverpod', 'Supabase', 'GoRouter', 'FL Chart'])
                Chip(
                  label: Text(tech, style: theme.textTheme.labelSmall),
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Empty state yang konsisten di seluruh aplikasi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showAnimation = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        )
            .animate(target: showAnimation ? 1 : 0)
            .scale(duration: 500.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        )
            .animate(target: showAnimation ? 1 : 0)
            .fadeIn(duration: 300.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 200.ms),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: showAnimation ? 1 : 0)
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 300.ms),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(AppIcons.add, size: 18),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          )
              .animate(target: showAnimation ? 1 : 0)
              .fadeIn(duration: 300.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: 400.ms),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: content,
        ),
      ),
    );
  }
}

/// Empty state untuk list (lebih ringkas).
class EmptyListState extends StatelessWidget {
  const EmptyListState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(AppIcons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state untuk search/filter hasil kosong.
class EmptySearchState extends StatelessWidget {
  const EmptySearchState({
    super.key,
    this.query = '',
    this.onClear,
  });

  final String query;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return EmptyState(
      icon: AppIcons.searchOffRounded,
      title: query.isEmpty ? l10n.noData : l10n.noResultsFound(query),
      subtitle: query.isNotEmpty ? l10n.tryDifferentSearch : null,
      actionLabel: query.isNotEmpty && onClear != null ? l10n.clearSearch : null,
      onAction: onClear,
    );
  }
}

/// Error state yang konsisten.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = AppIcons.errorOutlineRounded,
    this.showDetails = false,
    this.details,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData icon;
  final bool showDetails;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppTheme.error),
              )
                  .animate()
                  .shake(duration: 500.ms)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.oopsSomethingWrong,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (showDetails && details != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    details!,
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(AppIcons.refresh, size: 18),
                  label: Text(retryLabel ?? l10n.retry),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state inline (untuk dalam list/card).
class InlineErrorState extends StatelessWidget {
  const InlineErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      margin: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.errorOutlineRounded, color: AppTheme.error, size: compact ? 18 : 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.error),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh, size: compact ? 16 : 18),
              label: Text(l10n.retry, style: TextStyle(fontSize: compact ? 12 : 14)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.error,
                padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.sm : AppSpacing.md, vertical: AppSpacing.xs),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Network error state khusus.
class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({
    super.key,
    this.onRetry,
    this.isOffline = false,
  });

  final VoidCallback? onRetry;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ErrorState(
      icon: isOffline ? AppIcons.wifiOffRounded : AppIcons.cloudOffRounded,
      message: isOffline
          ? l10n.offlineMode
          : l10n.connectionError,
      onRetry: onRetry,
      retryLabel: isOffline ? l10n.goOnline : l10n.retryConnection,
    );
  }
}

/// Server error state.
class ServerErrorState extends StatelessWidget {
  const ServerErrorState({
    super.key,
    this.statusCode,
    this.onRetry,
  });

  final int? statusCode;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String message;
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          message = l10n.sessionExpired;
          break;
        case 403:
          message = l10n.accessDenied;
          break;
        case 404:
          message = l10n.resourceNotFound;
          break;
        case 500:
          message = l10n.serverError;
          break;
        default:
          message = l10n.serverErrorCode(statusCode.toString());
      }
    } else {
      message = l10n.serverError;
    }

    return ErrorState(
      icon: AppIcons.serverRounded,
      message: message,
      onRetry: onRetry,
    );
  }
}

/// Validation error state (untuk form).
class ValidationErrorState extends StatelessWidget {
  const ValidationErrorState({
    super.key,
    required this.errors,
    this.onDismiss,
  });

  final List<String> errors;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.errorOutlineRounded, color: AppTheme.error, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Validasi Gagal',
                style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.error, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(AppIcons.closeRounded, size: 18, color: AppTheme.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...errors.map((e) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 4),
            child: Text(
              '• $e',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
            ),
          )),
        ],
      ),
    );
  }
}
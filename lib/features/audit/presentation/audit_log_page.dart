import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/audit_log_repository.dart';

/// Halaman audit log.
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _startDate;
  DateTime? _endDate;
  AuditAction? _selectedAction;
  String? _selectedEntityType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditLog),
        actions: [
          IconButton(
            tooltip: l10n.exportCSV,
            onPressed: _exportCSV,
            icon: const Icon(AppIcons.downloadRounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _FilterBar(
            searchController: _searchController,
            onSearchChanged: (v) => setState(() => _query = v),
            startDate: _startDate,
            endDate: _endDate,
            onStartDateTap: () => _pickDate(isStart: true),
            onEndDateTap: () => _pickDate(isStart: false),
            selectedAction: _selectedAction,
            onActionChanged: (v) => setState(() => _selectedAction = v),
            selectedEntityType: _selectedEntityType,
            onEntityTypeChanged: (v) => setState(() => _selectedEntityType = v),
            onClearFilters: _clearFilters,
            l10n: l10n,
          ),
          // Log list
          Expanded(
            child: _AuditLogList(
              query: _query,
              startDate: _startDate,
              endDate: _endDate,
              action: _selectedAction,
              entityType: _selectedEntityType,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedAction = null;
      _selectedEntityType = null;
    });
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV - Coming soon')),
    );
  }
}

/// Filter bar untuk audit log.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
    required this.selectedAction,
    required this.onActionChanged,
    required this.selectedEntityType,
    required this.onEntityTypeChanged,
    required this.onClearFilters,
    required this.l10n,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;
  final AuditAction? selectedAction;
  final ValueChanged<AuditAction?> onActionChanged;
  final String? selectedEntityType;
  final ValueChanged<String?> onEntityTypeChanged;
  final VoidCallback onClearFilters;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.search,
              prefixIcon: const Icon(AppIcons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(AppIcons.closeRounded),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Date range & filters
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onStartDateTap,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.startDate,
                      prefixIcon: const Icon(AppIcons.calendarMonthRounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(startDate != null ? fmt.format(startDate!) : l10n.selectDate),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  onTap: onEndDateTap,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.endDate,
                      prefixIcon: const Icon(AppIcons.calendarMonthRounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(endDate != null ? fmt.format(endDate!) : l10n.selectDate),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AuditAction>(
                  initialValue: selectedAction,
                  decoration: InputDecoration(
                    labelText: l10n.action,
                    prefixIcon: const Icon(AppIcons.filterListRounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<AuditAction>(
                      value: null,
                      child: Text('Semua Aksi'),
                    ),
                    for (final action in AuditAction.values)
                      DropdownMenuItem(
                        value: action,
                        child: Text(_actionLabel(action, l10n)),
                      ),
                  ],
                  onChanged: onActionChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedEntityType,
                  decoration: InputDecoration(
                    labelText: l10n.entityType,
                    prefixIcon: const Icon(AppIcons.categoryRounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Tipe'),
                    ),
                    for (final type in _entityTypes)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                  ],
                  onChanged: onEntityTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(AppIcons.clearRounded, size: 18),
                label: Text(l10n.clearFilters),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionLabel(AuditAction action, AppLocalizations l10n) {
    switch (action) {
      case AuditAction.create:
        return 'Buat';
      case AuditAction.update:
        return 'Ubah';
      case AuditAction.delete:
        return 'Hapus';
      case AuditAction.login:
        return 'Masuk';
      case AuditAction.logout:
        return 'Keluar';
      case AuditAction.payment:
        return 'Pembayaran';
      case AuditAction.refund:
        return 'Refund';
      case AuditAction.stockAdjustment:
        return 'Penyesuaian Stok';
      case AuditAction.priceChange:
        return 'Perubahan Harga';
      case AuditAction.permissionChange:
        return 'Perubahan Izin';
      case AuditAction.settingsChange:
        return 'Perubahan Pengaturan';
      case AuditAction.dataExport:
        return 'Ekspor Data';
      case AuditAction.dataImport:
        return 'Impor Data';
      case AuditAction.sync:
        return 'Sinkronisasi';
    }
  }

  static const _entityTypes = [
    'products',
    'categories',
    'sales',
    'purchases',
    'expenses',
    'income',
    'users',
    'settings',
    'customers',
    'suppliers',
    'stock',
    'cash',
  ];
}

/// List audit log.
class _AuditLogList extends ConsumerWidget {
  const _AuditLogList({
    required this.query,
    required this.startDate,
    required this.endDate,
    required this.action,
    required this.entityType,
    required this.l10n,
  });

  final String query;
  final DateTime? startDate;
  final DateTime? endDate;
  final AuditAction? action;
  final String? entityType;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_auditLogsProvider(
      _AuditLogsParams(
        query: query,
        startDate: startDate,
        endDate: endDate,
        action: action,
        entityType: entityType,
      ),
    ));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return _EmptyState(
            icon: AppIcons.historyRounded,
            message: l10n.noAuditLogs,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: logs.length,
          itemBuilder: (_, index) => _AuditLogTile(log: logs[index], l10n: l10n),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _EmptyState(
        icon: AppIcons.errorOutlineRounded,
        message: 'Error: $e',
      ),
    );
  }
}

/// Parameters untuk audit logs provider.
class _AuditLogsParams {
  const _AuditLogsParams({
    required this.query,
    required this.startDate,
    required this.endDate,
    required this.action,
    required this.entityType,
  });

  final String query;
  final DateTime? startDate;
  final DateTime? endDate;
  final AuditAction? action;
  final String? entityType;
}

final _auditLogsProvider = FutureProvider.family<List<AuditLogEntity>, _AuditLogsParams>(
  (ref, params) async {
    final repo = ref.watch(auditLogRepositoryProvider);
    return repo.getLogs(
      query: params.query.isEmpty ? null : params.query,
      startDate: params.startDate,
      endDate: params.endDate,
      action: params.action,
      entityType: params.entityType,
    );
  },
);

/// Utility class untuk audit log UI helpers.
class AuditLogUI {
  static Color actionColor(BuildContext context, AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return AppTheme.success;
      case AuditAction.update:
        return AppTheme.warning;
      case AuditAction.delete:
        return AppTheme.error;
      case AuditAction.login:
        return AppTheme.info;
      case AuditAction.logout:
        return Theme.of(context).colorScheme.primary;
      case AuditAction.payment:
        return AppTheme.success;
      case AuditAction.refund:
        return AppTheme.error;
      case AuditAction.stockAdjustment:
        return AppTheme.warning;
      case AuditAction.priceChange:
        return const Color(0xFF8B5CF6);
      case AuditAction.permissionChange:
        return AppTheme.error;
      case AuditAction.settingsChange:
        return AppTheme.info;
      case AuditAction.dataExport:
        return AppTheme.warning;
      case AuditAction.dataImport:
        return AppTheme.info;
      case AuditAction.sync:
        return const Color(0xFF8B5CF6);
    }
  }

  static IconData actionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return AppIcons.add;
      case AuditAction.update:
        return AppIcons.edit;
      case AuditAction.delete:
        return AppIcons.delete;
      case AuditAction.login:
        return AppIcons.login;
      case AuditAction.logout:
        return AppIcons.logout;
      case AuditAction.payment:
        return AppIcons.paymentRounded;
      case AuditAction.refund:
        return AppIcons.moneyOffRounded;
      case AuditAction.stockAdjustment:
        return AppIcons.inventory2Rounded;
      case AuditAction.priceChange:
        return AppIcons.attachMoneyRounded;
      case AuditAction.permissionChange:
        return AppIcons.lockOutline;
      case AuditAction.settingsChange:
        return AppIcons.settingsRounded;
      case AuditAction.dataExport:
        return AppIcons.downloadRounded;
      case AuditAction.dataImport:
        return AppIcons.uploadRounded;
      case AuditAction.sync:
        return AppIcons.sync;
    }
  }

  /// Format tanggal aman: tangani baik format milliseconds (baru) maupun
  /// seconds (database lama) agar tidak throw FormatException di UI.
  static String formatDate(DateTime? date, {bool withSeconds = false}) {
    if (date == null) return '-';
    try {
      // Jika tahun < 2000, berarti disimpan dalam seconds (Unix epoch)
      // Kalikan 1000 → milidetik agar benar
      final d = date.year < 2000
          ? DateTime.fromMillisecondsSinceEpoch(
              date.millisecondsSinceEpoch * 1000,
              isUtc: true,
            )
          : date;
      final fmt = DateFormat(withSeconds ? 'dd/MM/yyyy HH:mm:ss' : 'dd/MM/yyyy HH:mm');
      return fmt.format(d.toLocal());
    } catch (_) {
      return '-';
    }
  }

  static String actionLabel(AuditAction action, AppLocalizations l10n) {
    switch (action) {
      case AuditAction.create:
        return 'Buat';
      case AuditAction.update:
        return 'Ubah';
      case AuditAction.delete:
        return 'Hapus';
      case AuditAction.login:
        return 'Masuk';
      case AuditAction.logout:
        return 'Keluar';
      case AuditAction.payment:
        return 'Pembayaran';
      case AuditAction.refund:
        return 'Refund';
      case AuditAction.stockAdjustment:
        return 'Penyesuaian Stok';
      case AuditAction.priceChange:
        return 'Perubahan Harga';
      case AuditAction.permissionChange:
        return 'Perubahan Izin';
      case AuditAction.settingsChange:
        return 'Perubahan Pengaturan';
      case AuditAction.dataExport:
        return 'Ekspor Data';
      case AuditAction.dataImport:
        return 'Impor Data';
      case AuditAction.sync:
        return 'Sinkronisasi';
    }
  }
}

/// Tile untuk audit log entry.
class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({
    required this.log,
    required this.l10n,
  });

  final AuditLogEntity log;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = AuditLogUI.actionColor(context, log.action);
    final actionIcon = AuditLogUI.actionIcon(log.action);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withValues(alpha: 0.15),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Text(
          log.description,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${log.entityType} (${log.entityId})',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              '${AuditLogUI.formatDate(log.createdAt)} · ${log.userName}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(AppIcons.visibilityRounded, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.viewDetail),
                ],
              ),
              onTap: () => _showDetail(context),
            ),
            if (log.oldValue != null || log.newValue != null)
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(AppIcons.compareRounded, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.viewChanges),
                  ],
                ),
                onTap: () => _showChanges(context),
              ),
          ],
        ),
        onTap: () => _showDetail(context),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AuditLogDetailSheet(log: log, l10n: l10n),
    );
  }

  void _showChanges(BuildContext context) {
    if (log.oldValue == null && log.newValue == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => _AuditLogChangesSheet(log: log, l10n: l10n),
    );
  }
}

/// Sheet detail audit log.
class _AuditLogDetailSheet extends StatelessWidget {
  const _AuditLogDetailSheet({
    required this.log,
    required this.l10n,
  });

  final AuditLogEntity log;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = AuditLogUI.actionColor(context, log.action);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: actionColor.withValues(alpha: 0.15),
                child: Icon(AuditLogUI.actionIcon(log.action), color: actionColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.description, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '${log.entityType} · ${log.entityId}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.closeRounded),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: l10n.user, value: log.userName),
          _DetailRow(label: l10n.action, value: AuditLogUI.actionLabel(log.action, l10n)),
          _DetailRow(label: l10n.entityType, value: log.entityType),
          _DetailRow(label: l10n.entityId, value: log.entityId),
          _DetailRow(label: l10n.timestamp, value: AuditLogUI.formatDate(log.createdAt, withSeconds: true)),
          if (log.ipAddress != null) _DetailRow(label: 'IP Address', value: log.ipAddress!),
          if (log.deviceInfo != null) _DetailRow(label: 'Device', value: log.deviceInfo!),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Sheet perubahan nilai.
class _AuditLogChangesSheet extends StatelessWidget {
  const _AuditLogChangesSheet({
    required this.log,
    required this.l10n,
  });

  final AuditLogEntity log;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.changes, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (log.oldValue != null)
            _ChangeRow(
              label: l10n.oldValue,
              value: log.oldValue!,
              color: AppTheme.error,
              icon: AppIcons.remove,
            ),
          if (log.newValue != null)
            _ChangeRow(
              label: l10n.newValue,
              value: log.newValue!,
              color: AppTheme.success,
              icon: AppIcons.add,
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
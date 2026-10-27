import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/cash_entity.dart';
import '../data/cash_repository.dart';

/// Halaman manajemen kas, rekening, dan sesi kasir.
class CashPage extends ConsumerStatefulWidget {
  const CashPage({super.key});

  @override
  ConsumerState<CashPage> createState() => _CashPageState();
}

class _CashPageState extends ConsumerState<CashPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashRegister),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.cashRegister),
            Tab(text: 'Rekening'),
            Tab(text: 'Sesi Kasir'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CashRegisterTab(l10n: l10n),
          _AccountsTab(l10n: l10n),
          _CashSessionsTab(l10n: l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-cash',
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _openRegisterForm(context);
              break;
            case 1:
              _openAccountForm(context);
              break;
            case 2:
              _openSessionForm(context);
              break;
          }
        },
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  void _openRegisterForm(BuildContext context,
      {CashRegisterEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CashRegisterForm(existing: existing),
    );
    ref.invalidate(cashRegistersProvider);
  }

  void _openAccountForm(BuildContext context,
      {AccountEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AccountForm(existing: existing),
    );
    ref.invalidate(accountsProvider);
  }

  void _openSessionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OpenSessionForm(),
    );
    ref.invalidate(cashSessionsProvider);
  }
}

/// Tab register kasir.
class _CashRegisterTab extends ConsumerWidget {
  const _CashRegisterTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final registers = ref.watch(cashRegistersProvider);

    return registers.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: AppIcons.accountBalanceRounded,
            message: 'Belum ada register kasir',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final r = items[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(AppIcons.accountBalanceRounded,
                    color: theme.colorScheme.primary, size: 20),
              ),
              title: Text(r.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(r.formattedOpeningBalance,
                  style: theme.textTheme.bodySmall),
              trailing: Switch(
                value: r.isActive,
                onChanged: (_) => _toggleRegister(ref, r),
              ),
              onTap: () => _editRegister(context, ref, r),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  void _toggleRegister(WidgetRef ref, CashRegisterEntity register) {
    ref.read(cashRepositoryProvider).saveCashRegister(
          register.copyWith(isActive: !register.isActive),
        );
  }

  void _editRegister(
      BuildContext context, WidgetRef ref, CashRegisterEntity register) {
    // TODO: Implementasi showModalBottomSheet untuk edit
  }
}

/// Tab rekening.
class _AccountsTab extends ConsumerWidget {
  const _AccountsTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider);

    return accounts.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: AppIcons.accountBalanceRounded,
            message: 'Belum ada rekening',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final a = items[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _typeColor(a.type).withValues(alpha: 0.15),
                child: Icon(_typeIcon(a.type),
                    color: _typeColor(a.type), size: 20),
              ),
              title: Text(a.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(a.typeLabel,
                  style: theme.textTheme.bodySmall),
              trailing: Text(a.formattedBalance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: a.balance >= 0 ? AppTheme.success : AppTheme.error,
                  )),
              onTap: () => _editAccount(context, ref, a),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'cash':
        return AppTheme.success;
      case 'bank':
        return AppTheme.info;
      case 'e_wallet':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.warning;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'cash':
        return AppIcons.accountBalanceRounded;
      case 'bank':
        return AppIcons.accountBalanceRounded;
      case 'e_wallet':
        return AppIcons.paymentRounded;
      default:
        return AppIcons.accountBalanceRounded;
    }
  }

  void _editAccount(
      BuildContext context, WidgetRef ref, AccountEntity account) {
    // TODO: Implementasi showModalBottomSheet untuk edit
  }
}

/// Tab sesi kasir.
class _CashSessionsTab extends ConsumerWidget {
  const _CashSessionsTab({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = ref.watch(cashSessionsProvider);

    return sessions.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: AppIcons.historyRounded,
            message: 'Belum ada sesi kasir',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final s = items[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: s.isOpen
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                child: Icon(
                  s.isOpen ? AppIcons.checkCircleOutlineRounded : AppIcons.historyRounded,
                  color: s.isOpen ? AppTheme.success : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              title: Text('Sesi ${s.id.substring(0, 8)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo Awal: ${s.formattedOpeningBalance}',
                      style: theme.textTheme.bodySmall),
                  if (s.isClosed) ...[
                    Text('Saldo Aktual: ${s.formattedActualBalance ?? '-'}',
                        style: theme.textTheme.bodySmall),
                    Text('Selisih: ${s.formattedDifference ?? '-'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (s.difference ?? 0) >= 0
                              ? AppTheme.success
                              : AppTheme.error,
                        )),
                  ],
                ],
              ),
              trailing: s.isOpen
                  ? FilledButton(
                      onPressed: () => _closeSessionDialog(context, ref, s),
                      child: Text(l10n.closeSession),
                    )
                  : Chip(
                      label: Text(l10n.close,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: theme.colorScheme.primary,
                    ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  Future<void> _closeSessionDialog(
      BuildContext context, WidgetRef ref, CashSessionEntity session) async {
    final actualCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.closeSession),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saldo Awal: ${session.formattedOpeningBalance}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: actualCtrl,
              decoration: InputDecoration(
                labelText: l10n.actualBalance,
                prefixIcon: const Icon(AppIcons.accountBalanceRounded),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final actual = double.tryParse(actualCtrl.text) ?? 0;
              final expected = session.openingBalance; // Simplified
              final diff = actual - expected;
              await ref.read(cashRepositoryProvider).closeSession(
                    sessionId: session.id,
                    actualBalance: actual,
                    expectedBalance: expected,
                    difference: diff,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

/// Form register kasir.
class _CashRegisterForm extends ConsumerStatefulWidget {
  const _CashRegisterForm({this.existing});

  final CashRegisterEntity? existing;

  @override
  ConsumerState<_CashRegisterForm> createState() => _CashRegisterFormState();
}

class _CashRegisterFormState extends ConsumerState<_CashRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameCtrl.text = widget.existing!.name;
      _balanceCtrl.text = widget.existing!.openingBalance.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final register = CashRegisterEntity(
      id: isEditing ? widget.existing!.id : Uuid().v4(),
      name: _nameCtrl.text.trim(),
      openingBalance: double.tryParse(_balanceCtrl.text) ?? 0,
      isActive: true,
    );

    await ref.read(cashRepositoryProvider).saveCashRegister(register);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? '${l10n.edit} ${l10n.cashRegister}' : '${l10n.add} ${l10n.cashRegister}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(labelText: l10n.openingBalance),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Saldo wajib diisi';
                if (double.tryParse(v) == null) return 'Saldo tidak valid';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Form rekening.
class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({this.existing});

  final AccountEntity? existing;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _type = 'cash';

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameCtrl.text = widget.existing!.name;
      _type = widget.existing!.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final account = AccountEntity(
      id: isEditing ? widget.existing!.id : Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      isActive: true,
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(cashRepositoryProvider).saveAccount(account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Ubah Rekening' : 'Tambah Rekening',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(labelText: 'Tipe Rekening'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Kas')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
                DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Form buka sesi kasir.
class _OpenSessionForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OpenSessionForm> createState() => _OpenSessionFormState();
}

class _OpenSessionFormState extends ConsumerState<_OpenSessionForm> {
  final _formKey = GlobalKey<FormState>();
  final _balanceCtrl = TextEditingController();
  String? _registerId;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_registerId == null) return;

    await ref.read(cashRepositoryProvider).openSession(
          registerId: _registerId!,
          openingBalance: double.tryParse(_balanceCtrl.text) ?? 0,
          openedBy: 'kasir', // TODO: ambil dari auth
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final registers = ref.watch(cashRegistersProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.openSession,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            registers.when(
              data: (items) => DropdownButtonFormField<String>(
                value: _registerId,
                decoration: InputDecoration(labelText: l10n.register),
                items: [
                  for (final r in items.where((r) => r.isActive))
                    DropdownMenuItem(value: r.id, child: Text(r.name)),
                ],
                onChanged: (v) => setState(() => _registerId = v),
                validator: (v) => v == null ? 'Pilih register' : null,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _balanceCtrl,
              decoration: InputDecoration(labelText: l10n.openingBalance),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Saldo wajib diisi';
                if (double.tryParse(v) == null) return 'Saldo tidak valid';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.open),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Empty state reusable.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

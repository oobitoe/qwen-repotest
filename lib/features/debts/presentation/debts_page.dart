import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../suppliers/data/supplier_repository.dart';
import '../../customers/data/customer_repository.dart';
import '../data/debt_entity.dart';
import '../data/debt_repository.dart';

/// Halaman manajemen hutang & piutang.
class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Hutang (Supplier)'),
              Tab(text: 'Piutang (Pelanggan)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DebtsTab(
                  query: _query,
                  type: 'payable',
                  l10n: l10n,
                  emptyIcon: AppIcons.accountBalanceRounded,
                  emptyMessage: 'Belum ada hutang supplier',
                  cardColor: AppTheme.error,
                  cardIcon: AppIcons.accountBalanceRounded,
                ),
                _DebtsTab(
                  query: _query,
                  type: 'receivable',
                  l10n: l10n,
                  emptyIcon: AppIcons.savingsRounded,
                  emptyMessage: 'Belum ada piutang pelanggan',
                  cardColor: AppTheme.success,
                  cardIcon: AppIcons.savingsRounded,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-debt',
        onPressed: () => _openDebtForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _openDebtForm(BuildContext context, {DebtEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DebtForm(
        existing: existing,
        defaultType: _tabController.index == 0 ? 'payable' : 'receivable',
      ),
    );
    ref.invalidate(debtsProvider);
  }
}

/// Tab daftar hutang/piutang.
class _DebtsTab extends ConsumerWidget {
  const _DebtsTab({
    required this.query,
    required this.type,
    required this.l10n,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.cardColor,
    required this.cardIcon,
  });

  final String query;
  final String type;
  final AppLocalizations l10n;
  final IconData emptyIcon;
  final String emptyMessage;
  final Color cardColor;
  final IconData cardIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    final debtsAsync = type == 'payable'
        ? ref.watch(payablesProvider)
        : ref.watch(receivablesProvider);

    return debtsAsync.when(
      data: (items) {
        final filtered = query.isEmpty
            ? items
            : items.where((d) {
                final q = query.toLowerCase();
                final supplierName = d.supplierId ?? '';
                final customerName = d.customerId ?? '';
                return supplierName.toLowerCase().contains(q) ||
                    customerName.toLowerCase().contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            icon: emptyIcon,
            message: emptyMessage,
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final d = filtered[i];
            final remaining = d.amount - d.paidAmount;
            final isOverdue = d.dueDate != null && 
                d.dueDate!.isBefore(DateTime.now()) &&
                d.status != 'paid';

            return Dismissible(
              key: ValueKey(d.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: AppTheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: const Icon(AppIcons.remove, color: Colors.white),
              ),
              onDismissed: (_) => _deleteDebt(context, ref, d.id),
              child: Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cardColor.withValues(alpha: 0.15),
                    child: Icon(cardIcon, color: cardColor, size: 20),
                  ),
                  title: Text(
                    d.isPayable ? 'Supplier: ${d.supplierId}' : 'Pelanggan: ${d.customerId}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.formattedAmount} (${d.statusLabel})',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (d.dueDate != null)
                        Text(
                          'Jatuh tempo: ${DateFormat('d MMM yyyy').format(d.dueDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue ? AppTheme.error : null,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        d.formattedRemainingAmount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining > 0 ? cardColor : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (d.paidAmount > 0)
                        Text(
                          'Dibayar: ${d.formattedPaidAmount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.success,
                          ),
                        ),
                    ],
                  ),
                  onTap: () => _showDebtDetail(context, ref, d),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  void _deleteDebt(BuildContext context, WidgetRef ref, String id) {
    ref.read(debtRepositoryProvider).deleteDebt(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hutang/Piutang dihapus')),
    );
  }

  Future<void> _showDebtDetail(
      BuildContext context, WidgetRef ref, DebtEntity debt) async {
    final payments = await ref.watch(debtRepositoryProvider).watchDebtPayments(debt.id).first;
    
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DebtDetailSheet(
        debt: debt,
        payments: payments,
        onAddPayment: () => _openPaymentForm(context, ref, debt),
      ),
    );
  }

  void _openPaymentForm(BuildContext context, WidgetRef ref, DebtEntity debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentForm(debt: debt),
    );
    ref.invalidate(debtsProvider);
  }
}

/// Form tambah/edit hutang/piutang.
class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({
    this.existing,
    required this.defaultType,
  });

  final DebtEntity? existing;
  final String defaultType;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  String _type = 'payable';
  String? _supplierId;
  String? _customerId;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _type = widget.defaultType;
    if (isEditing) {
      _amountCtrl.text = widget.existing!.amount.toString();
      _type = widget.existing!.type;
      _supplierId = widget.existing!.supplierId;
      _customerId = widget.existing!.customerId;
      if (widget.existing!.dueDate != null) {
        _dueDateCtrl.text = DateFormat('yyyy-MM-dd').format(widget.existing!.dueDate!);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final debt = DebtEntity(
      id: isEditing ? widget.existing!.id : const Uuid().v4(),
      type: _type,
      supplierId: _type == 'payable' ? _supplierId : null,
      customerId: _type == 'receivable' ? _customerId : null,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      paidAmount: isEditing ? widget.existing!.paidAmount : 0,
      status: isEditing ? widget.existing!.status : 'open',
      dueDate: _dueDateCtrl.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dueDateCtrl.text)
          : null,
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(debtRepositoryProvider).saveDebt(debt);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suppliers = ref.watch(suppliersProvider);
    final customers = ref.watch(customersProvider);

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
              isEditing ? 'Ubah ${_type == 'payable' ? 'Hutang' : 'Piutang'}' : 'Tambah ${_type == 'payable' ? 'Hutang' : 'Piutang'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipe'),
              items: const [
                DropdownMenuItem(value: 'payable', child: Text('Hutang (Supplier)')),
                DropdownMenuItem(value: 'receivable', child: Text('Piutang (Pelanggan)')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_type == 'payable')
              suppliers.when(
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _supplierId,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: [
                    for (final s in items.where((s) => s.isActive))
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                  validator: (v) => v == null ? 'Pilih supplier' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const SizedBox.shrink(),
              )
            else
              customers.when(
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _customerId,
                  decoration: const InputDecoration(labelText: 'Pelanggan'),
                  items: [
                    for (final c in items.where((c) => c.isActive))
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                  validator: (v) => v == null ? 'Pilih pelanggan' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(labelText: l10n.amount),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                if (double.tryParse(v) == null) return 'Jumlah tidak valid';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _dueDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Jatuh Tempo (YYYY-MM-DD)',
                prefixIcon: Icon(AppIcons.calendarMonthRounded),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  _dueDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                }
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

/// Sheet detail hutang/piutang dengan riwayat pembayaran.
class _DebtDetailSheet extends StatelessWidget {
  const _DebtDetailSheet({
    required this.debt,
    required this.payments,
    required this.onAddPayment,
  });

  final DebtEntity debt;
  final List<DebtPaymentEntity> payments;
  final VoidCallback onAddPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = debt.amount - debt.paidAmount;

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
              Expanded(
                child: Text(
                  debt.isPayable ? 'Detail Hutang' : 'Detail Piutang',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(AppIcons.closeRounded),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Tipe', value: debt.typeLabel),
          _DetailRow(label: debt.isPayable ? 'Supplier' : 'Pelanggan', value: debt.isPayable ? debt.supplierId ?? '-' : debt.customerId ?? '-'),
          _DetailRow(label: 'Total', value: debt.formattedAmount, valueStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          _DetailRow(label: 'Dibayar', value: debt.formattedPaidAmount, valueStyle: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.success)),
          _DetailRow(label: 'Sisa', value: debt.formattedRemainingAmount, valueStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: remaining > 0 ? AppTheme.error : AppTheme.success)),
          _DetailRow(label: 'Status', value: debt.statusLabel),
          if (debt.dueDate != null)
            _DetailRow(label: 'Jatuh Tempo', value: DateFormat('d MMM yyyy').format(debt.dueDate!)),
          const SizedBox(height: AppSpacing.lg),
          Text('Riwayat Pembayaran', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          if (payments.isEmpty)
            Text('Belum ada pembayaran', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          else
            Column(
              children: [
                for (final p in payments)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.15),
                      child: const Icon(AppIcons.paymentsRounded, color: AppTheme.success, size: 16),
                    ),
                    title: Text(p.formattedAmount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('d MMM yyyy HH:mm').format(p.paidAt)),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: debt.status == 'paid' ? null : onAddPayment,
              icon: const Icon(AppIcons.add),
              label: const Text('Tambah Pembayaran'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: valueStyle ?? theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Form tambah pembayaran.
class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.debt});

  final DebtEntity debt;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(debtRepositoryProvider).addPayment(
          debtId: widget.debt.id,
          amount: double.tryParse(_amountCtrl.text) ?? 0,
          createdBy: 'kasir',
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.debt.amount - widget.debt.paidAmount;

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
              'Tambah Pembayaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Sisa: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remaining)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: remaining > 0 ? AppTheme.error : AppTheme.success,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(labelText: l10n.amount),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                final amount = double.tryParse(v);
                if (amount == null) return 'Jumlah tidak valid';
                if (amount > remaining) return 'Melebihi sisa hutang/piutang';
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

/// Search bar reusable.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.l10n,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.search,
          prefixIcon: const Icon(AppIcons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
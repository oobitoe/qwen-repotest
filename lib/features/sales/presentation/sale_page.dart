import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/data/customer_repository.dart';
import '../data/sale_repository.dart';

/// Halaman penjualan & retur: daftar transaksi penjualan dan retur.
class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sales = ref.watch(salesProvider);

    return Scaffold(
      body: Column(
        children: [
          _SaleSearchBar(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: sales.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((s) {
                          final q = _query.toLowerCase();
                          return s.invoiceNumber.toLowerCase().contains(q) ||
                              s.customerName.toLowerCase().contains(q);
                        }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.receiptLongRounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.noData, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(s.invoiceNumber.substring(0, 1)),
                      ),
                      title: Text(s.invoiceNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.customerName}  ·  ${s.status}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        _idr(s.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: s.isCredit ? AppTheme.warning : null,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-sale',
        onPressed: () => _openSaleForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }

  Future<void> _openSaleForm(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _SaleForm(),
    );
    ref.invalidate(salesProvider);
  }
}

class _SaleSearchBar extends ConsumerWidget {
  const _SaleSearchBar({
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

class _SaleForm extends ConsumerStatefulWidget {
  const _SaleForm();

  @override
  ConsumerState<_SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends ConsumerState<_SaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  String? _customerId;
  String _paymentMethod = 'cash';
  bool _isCredit = false;

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_customerId == null) return;

    final repo = ref.read(saleRepositoryProvider);
    await repo.saveSale(
      invoiceNumber: _invoiceCtrl.text.trim(),
      customerId: _customerId!,
      customerName: _customerId!,
      subtotal: double.tryParse(_totalCtrl.text) ?? 0,
      discount: 0,
      tax: 0,
      total: double.tryParse(_totalCtrl.text) ?? 0,
      paymentMethod: _paymentMethod,
      isCredit: _isCredit,
      status: 'completed',
      cashierId: 'kasir',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Penjualan Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _invoiceCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Invoice'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              ref.watch(customersProvider).when(
                    data: (items) => DropdownButtonFormField<String>(
                      initialValue: _customerId,
                      decoration: const InputDecoration(labelText: 'Pelanggan'),
                      items: [
                        for (final c in items)
                          DropdownMenuItem(
                              value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _customerId = v),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _totalCtrl,
                decoration: const InputDecoration(labelText: 'Total'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                ],
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                title: const Text('Penjualan Kredit'),
                value: _isCredit,
                onChanged: (v) => setState(() => _isCredit = v ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

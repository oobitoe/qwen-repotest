import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../suppliers/data/supplier_repository.dart';
import '../data/purchase_repository.dart';
import 'package:intl/intl.dart';

/// Halaman manajemen pembelian.
class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final purchases = ref.watch(purchasesProvider);

    return Scaffold(
      body: Column(
        children: [
          _PurchaseSearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: purchases.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((p) {
                          final q = _query.toLowerCase();
                          return p.referenceNumber.toLowerCase().contains(q) ||
                              p.supplierName.toLowerCase().contains(q);
                        }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.shoppingCartRounded,
                            size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.noData, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(p.referenceNumber.substring(0, 1)),
                      ),
                      title: Text(p.referenceNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${p.supplierName}  ·  ${p.status}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        _idr(p.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: p.isCredit ? AppTheme.warning : null,
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
        heroTag: 'fab-add-purchase',
        onPressed: () => _openPurchaseForm(context),
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

  Future<void> _openPurchaseForm(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _PurchaseForm(),
    );
    ref.invalidate(purchasesProvider);
  }
}

class _PurchaseSearchBar extends ConsumerWidget {
  const _PurchaseSearchBar({
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

class _PurchaseForm extends ConsumerStatefulWidget {
  const _PurchaseForm();

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  String? _supplierId;
  String _paymentMethod = 'cash';
  bool _isCredit = false;

  @override
  void dispose() {
    _refCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_supplierId == null) return;

    final repo = ref.read(purchaseRepositoryProvider);
    await repo.savePurchase(
      referenceNumber: _refCtrl.text.trim(),
      supplierId: _supplierId!,
      supplierName: _supplierId!,
      items: [],
      subtotal: double.tryParse(_totalCtrl.text) ?? 0,
      discount: 0,
      tax: 0,
      total: double.tryParse(_totalCtrl.text) ?? 0,
      paymentMethod: _paymentMethod,
      isCredit: _isCredit,
      createdBy: 'kasir',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Pembelian Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Referensi'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              ref.watch(suppliersProvider).when(
                    data: (items) => DropdownButtonFormField<String>(
                      initialValue: _supplierId,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: [
                        for (final s in items)
                          DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name)),
                      ],
                      onChanged: (v) => setState(() => _supplierId = v),
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
                title: const Text('Pembelian Kredit'),
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

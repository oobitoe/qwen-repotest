import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/data/product_repository.dart';
import '../data/inventory_repository.dart';

/// Halaman inventaris: riwayat pergerakan stok, stok menipis,
/// dan form penyesuaian stok cepat.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String _selectedTab = 'movements'; // movements | adjustments | opname

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventory)),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: Row(
              children: [
                _TabButton(
                  label: l10n.stockMovements,
                  value: 'movements',
                  selected: _selectedTab == 'movements',
                  onTap: () => setState(() => _selectedTab = 'movements'),
                ),
                _TabButton(
                  label: 'Penyesuaian',
                  value: 'adjustments',
                  selected: _selectedTab == 'adjustments',
                  onTap: () => setState(() => _selectedTab = 'adjustments'),
                ),
                _TabButton(
                  label: 'Opname',
                  value: 'opname',
                  selected: _selectedTab == 'opname',
                  onTap: () => setState(() => _selectedTab = 'opname'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 'movements'
                ? _MovementsTab(l10n: l10n)
                : _selectedTab == 'adjustments'
                    ? _AdjustmentsTab(l10n: l10n)
                    : _OpnameTab(l10n: l10n),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-adjust-stock',
        onPressed: () => _openAdjustmentDialog(context),
        icon: const Icon(AppIcons.productionQuantityLimitsRounded),
        label: Text(l10n.adjustStock),
      ),
    );
  }

  Future<void> _openAdjustmentDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _AdjustmentDialog(),
    );
    ref.invalidate(stockMovementsProvider);
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: selected
              ? theme.colorScheme.primaryContainer
              : null,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.primary
                        : null,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MovementsTab extends ConsumerWidget {
  const _MovementsTab({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final movements = ref.watch(stockMovementsProvider);

    return movements.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.historyRounded,
                    size: 48, color: Colors.grey),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.noData, style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final m = items[i];
            final isIn = m.quantity >= 0;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isIn
                    ? AppTheme.success.withValues(alpha: 0.15)
                    : AppTheme.error.withValues(alpha: 0.15),
                child: Icon(
                  isIn ? AppIcons.arrowUpward : AppIcons.arrowDownward,
                  size: 18,
                  color: isIn ? AppTheme.success : AppTheme.error,
                ),
              ),
              title: Text('${m.type}  ·  ${m.productId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${m.quantity.toInt()} → saldo ${m.balanceAfter.toInt()}  ·  ${m.note ?? '-'}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                '${isIn ? '+' : ''}${m.quantity.toInt()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIn ? AppTheme.success : AppTheme.error,
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
}

class _AdjustmentsTab extends ConsumerWidget {
  const _AdjustmentsTab({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.productionQuantityLimitsRounded,
              size: 48, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text('Belum ada penyesuaian stok.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _OpnameTab extends ConsumerWidget {
  const _OpnameTab({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.inventory2Rounded,
              size: 48, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text('Belum ada stock opname.',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AdjustmentDialog extends ConsumerStatefulWidget {
  const _AdjustmentDialog();

  @override
  ConsumerState<_AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends ConsumerState<_AdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _productId;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_productId == null) return;

    final repo = ref.read(inventoryRepositoryProvider);
    await repo.recordMovement(
      productId: _productId!,
      type: 'adjustment',
      quantity: double.tryParse(_qtyCtrl.text) ?? 0,
      referenceType: 'adjustment',
      referenceId: 'manual',
      note: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      createdBy: 'kasir',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = ref.watch(productsProvider);

    return AlertDialog(
      title: const Text('Penyesuaian Stok'),
      content: products.when(
        data: (items) => Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _productId,
                decoration: const InputDecoration(labelText: 'Produk'),
                items: [
                  for (final p in items)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _productId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Stok Baru'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Alasan'),
              ),
            ],
          ),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (e, st) => const SizedBox.shrink(),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/data/category_repository.dart';
import '../../products/data/product_entity.dart';
import '../../products/data/product_repository.dart';

/// Halaman manajemen produk: daftar produk dengan pencarian, filter,
/// dan tombol tambah/edit/hapus.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
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
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.products)),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: products.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((p) {
                          final q = _query.toLowerCase();
                          return p.name.toLowerCase().contains(q) ||
                              p.sku.toLowerCase().contains(q) ||
                              (p.barcode ?? '').toLowerCase().contains(q);
                        }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.inventory2Rounded,
                            size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.noData,
                            style: theme.textTheme.bodyMedium),
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
                        child: Text(p.sku.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(p.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.sku}  ·  ${l10n.stock}: ${p.stock.toInt()}',
                          style: theme.textTheme.bodySmall),
                      trailing: Text(
                        _idr(p.sellPrice),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: p.stock <= p.minStock
                              ? AppTheme.error
                              : theme.colorScheme.onSurface,
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
        heroTag: 'fab-add-product',
        onPressed: () => _openProductForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _openProductForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ProductForm(),
    );
    ref.invalidate(productsProvider);
  }

  static String _idr(double v) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(v);
  }
}

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

/// Form tambah/edit produk.
class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm();

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  String? _categoryId;

  @override
  void dispose() {
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(productRepositoryProvider);
    await repo.saveProduct(ProductEntity(
      id: Uuid().v4(),
      sku: _skuCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      categoryId: _categoryId,
      costPrice: double.tryParse(_costCtrl.text) ?? 0,
      sellPrice: double.tryParse(_sellCtrl.text) ?? 0,
      minStock: double.tryParse(_minStockCtrl.text) ?? 0,
      stock: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.add} ${l10n.products}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (v) => (v == null || v.isEmpty) ? 'SKU wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(labelText: 'Barcode'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: AppSpacing.md),
            categories.when(
              data: (items) => DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in items)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(labelText: 'Harga Modal'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _sellCtrl,
              decoration: const InputDecoration(labelText: 'Harga Jual'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _minStockCtrl,
              decoration: const InputDecoration(labelText: 'Stok Minimum'),
              keyboardType: TextInputType.number,
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
          ],
        ),
      ),
    );
  }
}

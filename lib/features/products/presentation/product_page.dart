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
  int _currentPage = 1;
  final int _pageSize = 20;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final productsAsync = ref.watch(paginatedProductsStreamProvider((
      page: _currentPage,
      pageSize: _pageSize,
      query: _query,
      categoryId: _selectedCategoryId,
    )));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.products)),
      body: Column(
        children: [
          _SearchAndFilterBar(
            searchController: _searchController,
            onSearchChanged: (v) => setState(() {
              _query = v;
              _currentPage = 1;
            }),
            selectedCategoryId: _selectedCategoryId,
            onCategoryChanged: (v) => setState(() {
              _selectedCategoryId = v;
              _currentPage = 1;
            }),
            l10n: l10n,
          ),
          Expanded(
            child: productsAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return _EmptyState(
                    icon: AppIcons.inventory2Rounded,
                    message: l10n.noData,
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: result.items.length,
                        itemBuilder: (_, i) {
                          final p = result.items[i];
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
                      ),
                    ),
                    // Pagination controls
                    if (result.totalPages > 1)
                      _PaginationControls(
                        currentPage: _currentPage,
                        totalPages: result.totalPages,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        l10n: l10n,
                      ),
                  ],
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
    ref.invalidate(paginatedProductsProvider);
  }

  static String _idr(double v) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(v);
  }
}

class _SearchAndFilterBar extends ConsumerWidget {
  const _SearchAndFilterBar({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.l10n,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.search,
              prefixIcon: const Icon(AppIcons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          categories.when(
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              decoration: InputDecoration(
                labelText: l10n.category,
                prefixIcon: const Icon(AppIcons.categoryRounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Kategori'),
                ),
                for (final c in cats.where((c) => c.isActive))
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: onCategoryChanged,
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.l10n,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(AppIcons.chevronLeftRounded),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            tooltip: l10n.previousPage,
          ),
          Text('$currentPage / $totalPages',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(AppIcons.chevronRightRounded),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            tooltip: l10n.nextPage,
          ),
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
      id: const Uuid().v4(),
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
                initialValue: _categoryId,
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
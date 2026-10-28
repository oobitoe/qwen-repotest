import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/data/category_repository.dart';
import '../../products/data/product_entity.dart';
import 'package:uuid/uuid.dart';

/// Halaman manajemen kategori: daftar kategori dengan pencarian dan
/// tombol tambah/edit/hapus.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
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
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: categories.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((c) {
                          return c.name.toLowerCase().contains(_query.toLowerCase());
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
                    final c = filtered[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(AppIcons.storefrontRounded, size: 20),
                      ),
                      title: Text(c.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(c.isActive ? l10n.active : l10n.inactive,
                          style: theme.textTheme.bodySmall),
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
        heroTag: 'fab-add-category',
        onPressed: () => _openCategoryForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _openCategoryForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CategoryForm(),
    );
    ref.invalidate(categoriesProvider);
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

/// Form tambah/edit kategori.
class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm();

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(categoryRepositoryProvider);
    await repo.saveCategory(CategoryEntity(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.add} ${l10n.categories}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
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

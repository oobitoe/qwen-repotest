import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/income_entity.dart';
import '../data/income_repository.dart';

/// Halaman manajemen pemasukan & kategori pemasukan.
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
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
            tabs: [
              Tab(text: l10n.income),
              Tab(text: l10n.categories),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IncomesTab(query: _query, l10n: l10n),
                _IncomeCategoriesTab(query: _query, l10n: l10n),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-income',
        onPressed: () => _openIncomeForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _openIncomeForm(BuildContext context,
      {IncomeEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IncomeForm(existing: existing),
    );
    ref.invalidate(incomesProvider);
  }
}

/// Tab daftar pemasukan.
class _IncomesTab extends ConsumerWidget {
  const _IncomesTab({required this.query, required this.l10n});

  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final incomes = ref.watch(incomesProvider);

    return incomes.when(
      data: (items) {
        final filtered = query.isEmpty
            ? items
            : items.where((e) {
                final q = query.toLowerCase();
                return e.description.toLowerCase().contains(q) ||
                    (e.categoryId ?? '').toLowerCase().contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            icon: AppIcons.savingsRounded,
            message: l10n.noData,
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final e = filtered[i];
            return Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: AppTheme.success,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: const Icon(AppIcons.remove, color: Colors.white),
              ),
              onDismissed: (_) => _deleteIncome(context, ref, e.id),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.success.withValues(alpha: 0.15),
                  child: const Icon(AppIcons.savingsRounded,
                      color: AppTheme.success, size: 20),
                ),
                title: Text(e.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${e.formattedAmount}  ·  ${_paymentMethodLabel(e.paymentMethod)}',
                    style: theme.textTheme.bodySmall),
                trailing: Text(e.formattedAmount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    )),
                onTap: () => _editIncome(context, ref, e),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      case 'card':
        return 'Kartu';
      default:
        return 'Lainnya';
    }
  }

  void _editIncome(
      BuildContext context, WidgetRef ref, IncomeEntity income) {
    // TODO: Implementasi showModalBottomSheet untuk edit
  }

  void _deleteIncome(BuildContext context, WidgetRef ref, String id) {
    ref.read(incomeRepositoryProvider).deleteIncome(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pemasukan dihapus')),
    );
  }
}

/// Tab kategori pemasukan.
class _IncomeCategoriesTab extends ConsumerWidget {
  const _IncomeCategoriesTab({required this.query, required this.l10n});

  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(incomeCategoriesProvider);

    return categories.when(
      data: (items) {
        final filtered = query.isEmpty
            ? items
            : items.where((c) {
                return c.name.toLowerCase().contains(query.toLowerCase());
              }).toList();

        if (filtered.isEmpty) {
          return _EmptyState(
            icon: AppIcons.categoryRounded,
            message: l10n.noData,
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final c = filtered[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    AppTheme.success.withValues(alpha: 0.15),
                child: const Icon(AppIcons.categoryRounded,
                    color: AppTheme.success, size: 20),
              ),
              title: Text(c.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(c.isActive ? 'Aktif' : 'Tidak Aktif',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.isActive ? AppTheme.success : AppTheme.warning,
                  )),
              trailing: Switch(
                value: c.isActive,
                onChanged: (_) => _toggleCategory(ref, c),
              ),
              onTap: () => _editCategory(context, ref, c),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  void _toggleCategory(WidgetRef ref, IncomeCategoryEntity category) {
    ref.read(incomeRepositoryProvider).saveIncomeCategory(
          category.copyWith(isActive: !category.isActive),
        );
  }

  void _editCategory(
      BuildContext context, WidgetRef ref, IncomeCategoryEntity category) {
    _openCategoryForm(context, existing: category);
  }

  void _openCategoryForm(BuildContext context,
      {IncomeCategoryEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IncomeCategoryForm(existing: existing),
    );
  }
}

/// Form tambah/edit pemasukan.
class _IncomeForm extends ConsumerStatefulWidget {
  const _IncomeForm({this.existing});

  final IncomeEntity? existing;

  @override
  ConsumerState<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<_IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  String? _categoryId;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _descCtrl.text = widget.existing!.description;
      _amountCtrl.text = widget.existing!.amount.toString();
      _paymentMethod = widget.existing!.paymentMethod;
      _categoryId = widget.existing!.categoryId;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final income = IncomeEntity(
      id: isEditing ? widget.existing!.id : const Uuid().v4(),
      categoryId: _categoryId,
      description: _descCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      paymentMethod: _paymentMethod,
      createdBy: 'kasir', // TODO: ambil dari auth
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(incomeRepositoryProvider).saveIncome(income);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(incomeCategoriesProvider);

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
              isEditing ? '${l10n.edit} ${l10n.income}' : '${l10n.add} ${l10n.income}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Deskripsi wajib diisi' : null,
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
            categories.when(
              data: (items) => DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: l10n.categories),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tanpa Kategori'),
                  ),
                  for (final c in items.where((c) => c.isActive))
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                labelText: l10n.metodePembayaran,
                prefixIcon: const Icon(AppIcons.paymentRounded),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                DropdownMenuItem(value: 'card', child: Text('Kartu')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v!),
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

/// Form tambah/edit kategori pemasukan.
class _IncomeCategoryForm extends ConsumerStatefulWidget {
  const _IncomeCategoryForm({this.existing});

  final IncomeCategoryEntity? existing;

  @override
  ConsumerState<_IncomeCategoryForm> createState() =>
      _IncomeCategoryFormState();
}

class _IncomeCategoryFormState extends ConsumerState<_IncomeCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) _nameCtrl.text = widget.existing!.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final category = IncomeCategoryEntity(
      id: isEditing ? widget.existing!.id : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      isActive: true,
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(incomeRepositoryProvider).saveIncomeCategory(category);
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
              isEditing ? '${l10n.edit} ${l10n.categories}' : '${l10n.add} ${l10n.categories}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
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

/// Komponen search bar reusable.
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
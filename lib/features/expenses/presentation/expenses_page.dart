import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/expense_entity.dart';
import '../data/expense_repository.dart';

/// Halaman manajemen pengeluaran & kategori pengeluaran.
class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage>
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
      appBar: AppBar(
        title: Text(l10n.expenses),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.expenses),
            Tab(text: l10n.categories),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.syncNow,
            onPressed: () => ref
                .read(expenseRepositoryProvider)
                .saveExpenseCategory(
                  ExpenseCategoryEntity(
                    id: Uuid().v4(),
                    name: 'Test',
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                ),
            icon: const Icon(AppIcons.sync),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExpensesTab(query: _query, l10n: l10n),
                _ExpenseCategoriesTab(query: _query, l10n: l10n),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-add-expense',
        onPressed: () => _openExpenseForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _openExpenseForm(BuildContext context,
      {ExpenseEntity? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseForm(existing: existing),
    );
    ref.invalidate(expensesProvider);
  }
}

/// Tab daftar pengeluaran.
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.query, required this.l10n});

  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expenses = ref.watch(expensesProvider);

    return expenses.when(
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
            icon: AppIcons.receiptLongRounded,
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
                color: AppTheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: const Icon(AppIcons.remove, color: Colors.white),
              ),
              onDismissed: (_) => _deleteExpense(context, ref, e.id),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.error.withValues(alpha: 0.15),
                  child: Icon(AppIcons.receiptLongRounded,
                      color: AppTheme.error, size: 20),
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
                      color: AppTheme.error,
                    )),
                onTap: () => _editExpense(context, ref, e),
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

  void _editExpense(
      BuildContext context, WidgetRef ref, ExpenseEntity expense) {
    // Navigasi ke form edit
    _openExpenseForm(context, existing: expense);
  }

  void _deleteExpense(BuildContext context, WidgetRef ref, String id) {
    ref.read(expenseRepositoryProvider).deleteExpense(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pengeluaran dihapus')),
    );
  }

  void _openExpenseForm(BuildContext context,
      {ExpenseEntity? existing}) {
    // TODO: Implementasi showModalBottomSheet untuk edit
    // Untuk sekarang kosongkan
  }
}

/// Tab kategori pengeluaran.
class _ExpenseCategoriesTab extends ConsumerWidget {
  const _ExpenseCategoriesTab({required this.query, required this.l10n});

  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(expenseCategoriesProvider);

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
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(AppIcons.categoryRounded,
                    color: theme.colorScheme.primary, size: 20),
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

  void _toggleCategory(WidgetRef ref, ExpenseCategoryEntity category) {
    ref.read(expenseRepositoryProvider).saveExpenseCategory(
          category.copyWith(isActive: !category.isActive),
        );
  }

  void _editCategory(
      BuildContext context, WidgetRef ref, ExpenseCategoryEntity category) {
    _openCategoryForm(context, existing: category);
  }

  void _openCategoryForm(BuildContext context,
      {ExpenseCategoryEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseCategoryForm(existing: existing),
    );
  }
}

/// Form tambah/edit pengeluaran.
class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({this.existing});

  final ExpenseEntity? existing;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
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

    final expense = ExpenseEntity(
      id: isEditing ? widget.existing!.id : Uuid().v4(),
      categoryId: _categoryId,
      description: _descCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      paymentMethod: _paymentMethod,
      createdBy: 'kasir', // TODO: ambil dari auth
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(expenseRepositoryProvider).saveExpense(expense);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(expenseCategoriesProvider);

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
              isEditing ? '${l10n.edit} ${l10n.expenses}' : '${l10n.add} ${l10n.expenses}',
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
                value: _categoryId,
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
              value: _paymentMethod,
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

/// Form tambah/edit kategori pengeluaran.
class _ExpenseCategoryForm extends ConsumerStatefulWidget {
  const _ExpenseCategoryForm({this.existing});

  final ExpenseCategoryEntity? existing;

  @override
  ConsumerState<_ExpenseCategoryForm> createState() =>
      _ExpenseCategoryFormState();
}

class _ExpenseCategoryFormState extends ConsumerState<_ExpenseCategoryForm> {
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

    final category = ExpenseCategoryEntity(
      id: isEditing ? widget.existing!.id : Uuid().v4(),
      name: _nameCtrl.text.trim(),
      isActive: true,
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(expenseRepositoryProvider).saveExpenseCategory(category);
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
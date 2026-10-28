import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../suppliers/data/supplier_entity.dart';
import '../../suppliers/data/supplier_repository.dart';

/// Halaman manajemen supplier.
class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
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
    final suppliers = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.suppliers)),
      body: Column(
        children: [
          _SupplierSearchBar(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            l10n: l10n,
          ),
          Expanded(
            child: suppliers.when(
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((s) {
                          final q = _query.toLowerCase();
                          return s.name.toLowerCase().contains(q) ||
                              (s.phone ?? '').toLowerCase().contains(q);
                        }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.storefrontRounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
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
                    final s = filtered[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(s.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(s.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${s.phone ?? '-'}  ·  ${s.email ?? '-'}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Switch(
                        value: s.isActive,
                        onChanged: (_) {},
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
        heroTag: 'fab-add-supplier',
        onPressed: () => _openSupplierForm(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.add),
      ),
    );
  }

  Future<void> _openSupplierForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SupplierForm(),
    );
    ref.invalidate(suppliersProvider);
  }
}

class _SupplierSearchBar extends ConsumerWidget {
  const _SupplierSearchBar({
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

class _SupplierForm extends ConsumerStatefulWidget {
  const _SupplierForm();

  @override
  ConsumerState<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(supplierRepositoryProvider);
    await repo.saveSupplier(SupplierEntity(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
            Text('${l10n.add} ${l10n.suppliers}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Catatan'),
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

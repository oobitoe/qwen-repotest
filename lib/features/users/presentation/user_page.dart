import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/database/app_database.dart';
import '../application/user_controller.dart';
import '../../auth/application/auth_controller.dart';

/// Halaman Manajemen Pengguna — hanya dapat diakses oleh Owner.
/// Owner dapat menambah, mengubah, dan menonaktifkan pengguna untuk bisnisnya.
class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();
  String _selectedRole = 'kasir';
  Profile? _editingUser;
  bool _busy = false;

  // Role yang tersedia untuk dibuat Owner (Owner itu sendiri dikunci)
  static const List<Map<String, String>> availableRoles = [
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'manager', 'label': 'Manager'},
    {'value': 'kasir', 'label': 'Kasir'},
    {'value': 'staff_gudang', 'label': 'Staff Gudang'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userControllerProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Cek apakah user login adalah Owner.
  bool get _isOwner => ref.read(currentRoleProvider) == UserRole.owner;

  Future<void> _submitUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    try {
      final id = _editingUser?.id ?? const Uuid().v4();
      if (_editingUser == null) {
        await ref.read(userControllerProvider.notifier).createUser(
              id: id,
              email: _email.text.trim(),
              fullName: _fullName.text.trim(),
              role: _selectedRole,
              password: _password.text.trim().isEmpty ? null : _password.text.trim(),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ref.read(userControllerProvider.notifier).updateUser(
              id: id,
              email: _email.text.trim(),
              fullName: _fullName.text.trim(),
              role: _selectedRole,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna berhasil diperbarui.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivateUser(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan Pengguna?'),
        content: Text('Apakah Anda yakin ingin menonaktifkan "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(userControllerProvider.notifier).deactivateUser(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengguna telah dinonaktifkan.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openAddUserDialog() {
    _editingUser = null;
    _email.clear();
    _fullName.clear();
    _password.clear();
    _selectedRole = 'kasir';
    _showUserFormDialog();
  }

  void _openEditUserDialog(Profile user) {
    _editingUser = user;
    _email.text = user.email;
    _fullName.text = user.fullName;
    _selectedRole = user.role;
    _password.clear(); // Password tidak ditampilkan saat edit
    _showUserFormDialog();
  }

  void _showUserFormDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingUser == null ? 'Tambah Pengguna' : 'Ubah Pengguna'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullName,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(AppIcons.personRounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(AppIcons.mailOutline),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_editingUser == null) ...[
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: Icon(AppIcons.lockOutline),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Peran',
                    prefixIcon: Icon(AppIcons.lockOutline),
                  ),
                  initialValue: _selectedRole,
                  items: availableRoles
                      .map((r) => DropdownMenuItem(
                            value: r['value'],
                            child: Text(r['label']!),
                          ))
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selectedRole = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _busy ? null : _submitUser,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editingUser == null ? 'Buat' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  String _roleDisplayName(String role) {
    return switch (role) {
      'owner' => 'Owner',
      'admin' => 'Admin',
      'manager' => 'Manager',
      'kasir' => 'Kasir',
      'staff_gudang' => 'Staff Gudang',
      _ => role,
    };
  }

  Color _roleColor(String role) {
    return switch (role) {
      'owner' => Colors.amber,
      'admin' => Colors.blue,
      'manager' => Colors.indigo,
      'kasir' => Colors.green,
      'staff_gudang' => Colors.purple,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userState = ref.watch(userControllerProvider);

    // Guard: hanya Owner yang boleh masuk ke sini
    if (!_isOwner) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.lockOutline, size: 64, color: scheme.error),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Akses Dibatasi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Hanya Owner yang dapat mengelola pengguna.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: userState.isLoading
                ? null
                : () => ref.read(userControllerProvider.notifier).loadUsers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _openAddUserDialog,
        icon: const Icon(AppIcons.personAddRounded),
        label: const Text('Tambah Pengguna'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(userControllerProvider.notifier).loadUsers(),
        child: userState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : userState.users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.personRounded, size: 64, color: scheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Belum Ada Pengguna',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tambah pengguna pertama untuk bisnis Anda.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: _busy ? null : _openAddUserDialog,
                          icon: const Icon(AppIcons.personAddRounded),
                          label: const Text('Tambah Pengguna'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: userState.users.length,
                    itemBuilder: (context, index) {
                      final user = userState.users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: _roleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.xs),
                              Text(user.email),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: _roleColor(user.role).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  _roleDisplayName(user.role),
                                  style: TextStyle(
                                    color: _roleColor(user.role),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (user.role != 'owner')
                                IconButton(
                                  icon: const Icon(AppIcons.edit, color: Colors.blue),
                                  onPressed: _busy ? null : () => _openEditUserDialog(user),
                                  tooltip: 'Ubah',
                                ),
                              if (user.role != 'owner' && user.isActive)
                                IconButton(
                                  icon: const Icon(AppIcons.delete, color: Colors.red),
                                  onPressed: _busy
                                      ? null
                                      : () => _deactivateUser(user.id, user.fullName),
                                  tooltip: 'Nonaktifkan',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

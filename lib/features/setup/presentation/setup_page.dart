import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/setup_controller.dart';

/// Halaman setup pertama kali: konfigurasi bisnis & toko, lalu akun Owner pertama.
///
/// Alur:
/// 1. Jika tabel `businesses` kosong → isi form bisnis & toko.
/// 2. Setelah bisnis tersimpan, cek apakah sudah ada user (PocketBase + lokal).
/// 3. Jika BELUM ada user sama sekali → wajib daftar Owner pertama.
///    Role dikunci menjadi Owner dan tidak dapat diubah.
/// 4. Setelah Owner terdaftar → arahkan ke halaman Login.
///
/// Wajib online + PocketBase reachable sebelum dapat melanjutkan.
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _businessCurrency = TextEditingController(text: 'IDR');
  final _businessTimezone = TextEditingController(text: 'Asia/Jakarta');
  final _storeName = TextEditingController();
  final _storeAddress = TextEditingController();
  final _storePhone = TextEditingController();

  // Form Owner pertama
  final _ownerFormKey = GlobalKey<FormState>();
  final _ownerFullName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  String? _businessId; // ID bisnis yang baru dibuat (untuk tag user)
  String? _storeId; // ID toko yang baru dibuat (untuk tag user)
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Cek apakah setup diperlukan + verifikasi online + PocketBase reachable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(setupControllerProvider.notifier).checkFirstRun();
    });
  }

  @override
  void dispose() {
    _businessName.dispose();
    _businessCurrency.dispose();
    _businessTimezone.dispose();
    _storeName.dispose();
    _storeAddress.dispose();
    _storePhone.dispose();
    _ownerFullName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    super.dispose();
  }

  /// Langkah 0: Simpan bisnis & toko, lalu lanjut ke langkah Owner pertama jika diperlukan.
  Future<void> _submitBusiness() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    try {
      final businessId = await ref.read(setupControllerProvider.notifier).completeSetup(
            businessName: _businessName.text.trim(),
            businessCurrency: _businessCurrency.text.trim(),
            businessTimezone: _businessTimezone.text.trim(),
            storeName: _storeName.text.trim(),
            storeAddress: _storeAddress.text.trim().isEmpty
                ? null
                : _storeAddress.text.trim(),
            storePhone: _storePhone.text.trim().isEmpty
                ? null
                : _storePhone.text.trim(),
          );

      if (!mounted) return;

      // Simpan businessId dan storeId untuk langkah pendaftaran Owner pertama
      _businessId = businessId;
      final storeRow = await (ref.read(setupControllerProvider.notifier).db.select(ref.read(setupControllerProvider.notifier).db.stores)
            ..where((t) => t.businessId.equals(businessId))
            ..where((t) => t.deletedAt.isNull()))
          .getSingleOrNull();
      _storeId = storeRow?.id;

      if (!mounted) return;
      final setupState = ref.read(setupControllerProvider);
      if (setupState.needsFirstOwner) {
        // Belum ada Owner di kedua database → lanjut ke pendaftaran Owner pertama
        setState(() => _busy = false);
      } else {
        // Owner sudah ada → langsung ke login
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal setup bisnis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Langkah 1: Daftar Owner pertama (role selalu Owner, tidak bisa diubah).
  Future<void> _submitOwner() async {
    if (!(_ownerFormKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    try {
      await ref.read(setupControllerProvider.notifier).registerFirstOwner(
            email: _ownerEmail.text.trim(),
            password: _ownerPassword.text.trim(),
            fullName: _ownerFullName.text.trim(),
            businessId: _businessId, // businessId sudah dijamin ada saat langkah 1
            storeId: _storeId, // storeId sudah dijamin ada saat langkah 1
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun Owner pertama berhasil dibuat. Silakan masuk.'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal daftar Owner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final setupState = ref.watch(setupControllerProvider);

    // Tampilkan pesan error jika setup diblokir (offline / PB tidak reachable)
    if (setupState.status == SetupStatus.error && setupState.error != null) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(AppIcons.errorOutlineRounded,
                          size: 56, color: scheme.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Setup Diblokir',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        setupState.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: () =>
                            ref.read(setupControllerProvider.notifier).checkFirstRun(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sedang memeriksa koneksi + PocketBase — tampilkan loading, JANGAN form setup
    if (setupState.status == SetupStatus.checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Memeriksa koneksi dan server PocketBase…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Jika siap dan tidak perlu setup, kembali ke route (harus redirect otomatis)
    if (setupState.status == SetupStatus.ready && !setupState.needsSetup) {
      // Kalau belum ada Owner → tampilkan form Owner pertama, jangan ke login
      if (setupState.needsFirstOwner) {
        // Ambil businessId yang sudah ada untuk tag user Owner
        if (_businessId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final existingBusinessId =
                await ref.read(setupControllerProvider.notifier).getFirstBusinessId();
            if (mounted) {
              setState(() => _businessId = existingBusinessId ?? '');
            }
          });
        }
        // Jatuh ke form Owner pertama di bawah (langkah 1)
      } else {
        return const Scaffold(
          body: Center(
            child: Text('Setup tidak diperlukan. Mengarahkan ke login...'),
          ),
        );
      }
    }

    // Jika perlu setup tapi belum Online/PB reachable, tunggu (tidak boleh melanjutkan)
    if (setupState.status == SetupStatus.needsSetup &&
        (!setupState.online || !setupState.pocketbaseReachable)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Menunggu koneksi online dan database server…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Langkah 1: Form Daftar Owner Pertama (tambahan: bisnis sudah ada tapi belum ada Owner)
    if (setupState.needsFirstOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Owner Pertama'),
          leading: const BackButton(),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _ownerFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(AppIcons.personAddRounded,
                            size: 56, color: scheme.primary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Buat Akun Owner Pertama',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Akun ini akan memiliki peran Owner dan tidak dapat diubah. '
                          'Owner bertanggung jawab mengelola pengguna lain di dalam aplikasi.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _ownerFullName,
                          enabled: !_busy,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: l10n.fullName,
                            prefixIcon: const Icon(AppIcons.personRounded),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? l10n.nameRequired : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _ownerEmail,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(AppIcons.mailOutline),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? l10n.invalidEmail
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _ownerPassword,
                          enabled: !_busy,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(AppIcons.lockOutline),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? l10n.minPasswordLength
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Role dikunci ke Owner — hanya ditampilkan, tidak bisa diubah
                        InputDecoratorField(
                          label: l10n.role,
                          value: 'Owner',
                          icon: const Icon(AppIcons.lockOutline),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed:
                              (_busy || _businessId == null) ? null : _submitOwner,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Daftar sebagai Owner'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Langkah 0: Form Bisnis & Toko
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Pertama Kali'),
        leading: const BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(AppIcons.storefrontRounded,
                          size: 56, color: scheme.primary),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Setup Bisnis & Toko',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Isi data bisnis dan toko sebelum membuat akun pengguna.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _businessName,
                        enabled: !_busy,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: l10n.businessName,
                          prefixIcon: const Icon(AppIcons.storefrontRounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.nameRequired : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _businessCurrency,
                        enabled: !_busy,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: l10n.currency,
                          prefixIcon: const Icon(AppIcons.attachMoneyRounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.nameRequired : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _businessTimezone,
                        enabled: !_busy,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: l10n.timezone,
                          prefixIcon: const Icon(AppIcons.clockRounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.nameRequired : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Detail Toko',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _storeName,
                        enabled: !_busy,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: l10n.storeName,
                          prefixIcon: const Icon(AppIcons.storefrontRounded),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.nameRequired : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _storeAddress,
                        enabled: !_busy,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Toko',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _storePhone,
                        enabled: !_busy,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telepon Toko',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _busy ? null : _submitBusiness,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Simpan & Lanjutkan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget untuk menampilkan label role yang dikunci (bukan dropdown).
class InputDecoratorField extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const InputDecoratorField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

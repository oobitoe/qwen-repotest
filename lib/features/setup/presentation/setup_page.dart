import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../application/setup_controller.dart';

/// Halaman setup pertama kali: konfigurasi bisnis & toko.
///
/// Hanya muncul saat tabel `businesses` kosong (belum pernah setup).
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);

    try {
      await ref.read(setupControllerProvider.notifier).completeSetup(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup selesai. Bisnis dan toko telah disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRoutes.register);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal setup: $e'),
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

    // Jika siap dan perlu setup, tampilkan form
    if (setupState.status == SetupStatus.needsSetup) {
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
                          onPressed: _busy ? null : _submit,
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

    // Jika siap dan tidak perlu setup, kembali ke route (should redirect automatically)
    if (setupState.status == SetupStatus.ready && !setupState.needsSetup) {
      return const Scaffold(
        body: Center(
          child: Text('Setup tidak diperlukan. Mengarahkan ke login...'),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

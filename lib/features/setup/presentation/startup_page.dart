import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/setup_controller.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Splash / startup screen yang dijalankan saat aplikasi pertama kali dibuka.
///
/// Alur first-run (di-drive oleh [SetupController.checkFirstRun]):
/// 1. Periksa tabel `businesses` — jika sudah ada isi, setup tidak diperlukan.
/// 2. Jika kosong, periksa koneksi internet.
/// 3. Jika online, periksa apakah PocketBase reachable.
/// 4. Jika tidak terhubung (offline / PB unreachable) → tampilkan error
///    dengan tombol **Coba Lagi**.
/// 5. Jika terhubung → [SetupController] mengubah status ke `needsSetup`,
///    router redirect akan menavigasi ke `/setup` (first-run form).
/// 6. Jika tidak perlu setup → router redirect men navigasi ke `/login`
///    atau `/dashboard` sesuai status auth.
///
/// Halaman ini **hanya menampilkan UI** (loading / error). Navigasi
/// dilakukan oleh `routerProvider.redirect` yang mendengarkan perubahan
/// state pada [setupControllerProvider].
class StartupPage extends ConsumerStatefulWidget {
  const StartupPage({super.key});

  @override
  ConsumerState<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<StartupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(setupControllerProvider.notifier).checkFirstRun();
    });
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    // Tampilkan error jika pemeriksaan koneksi gagal
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
                        onPressed: () => ref
                            .read(setupControllerProvider.notifier)
                            .checkFirstRun(),
                        child: Text(l10n.retry),
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

    // Sedang memeriksa — tampilkan splash loading
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  scheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ]),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(AppIcons.storefrontRounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.appDisplayName,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Memeriksa koneksi dan server PocketBase\...',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/database/sync_registry.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hapus database lama saat schema berubah (v1 -> v2 dengan businessId + storeId)
  // Data lama akan dihapus dan dibuat ulang seed baru saat onCreate dijalankan
  await _deleteDatabaseIfNeeded();

  // Muat environment variabel (.env) sebelum inisialisasi layanan lain,
  // agar POCKETBASE_URL dan sebagainya tersedia untuk PocketBaseClient.
  // Jangan crash aplikasi bila .env belum ada — gunakan default.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Peringatan: .env tidak ditemukan, menggunakan default POCKETBASE_URL.');
  }

  // Initialize database singleton BEFORE runApp to avoid multiple instances warning Drift.
  final db = initializeDatabase();

  // Register sync metas once at app startup
  registerAllSyncMetas(db);

  runApp(const ProviderScope(child: PosApp()));
}

/// Hapus database SQLite lama jika ada (untuk migrasi skema v1 -> v2).
/// Data lama akan dihapus dan dibuat ulang seed baru dengan businessId + storeId.
Future<void> _deleteDatabaseIfNeeded() async {
  final homeDir = Platform.environment['HOME'] ?? '/tmp';
  final dbDir = Directory(p.join(homeDir, '.pos_database'));
  final dbFile = File(p.join(dbDir.path, 'pos_database.sqlite'));
  if (dbFile.existsSync()) {
    await dbFile.delete();
    debugPrint('Database lama dihapus: ${dbFile.path}');
  }
}

class PosApp extends ConsumerWidget {
  const PosApp({super.key, this.themeModeOverride});

  /// Override mode tema (dipakai pada pengujian agar deterministik).
  final ThemeMode? themeModeOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppLocalizations.of(context)?.appDisplayName ?? 'PrimePOS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeModeOverride ?? themeMode,
      locale: locale,
      routerConfig: router,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          _ConnectivityWatcher(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Memantau perubahan koneksi di luar langkah build MaterialApp
/// (Riverpod mengharuskan ref.listen berada dalam build method ConsumerWidget).
class _ConnectivityWatcher extends ConsumerWidget {
  const _ConnectivityWatcher({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(connectivityStreamProvider, (_, next) {
      updateConnectivity(next.value ?? const []);
    }, onError: (_, __) {});
    return child;
  }
}

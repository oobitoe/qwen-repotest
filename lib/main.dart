import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'core/database/sync_registry.dart';
import 'core/security/encrypted_database_manager.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi enkripsi database sebelum database dibuat
  await _initializeDatabaseEncryption();

  // Hapus database lama saat schema berubah (v1 -> v2 dengan businessId + storeId)
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

/// Inisialisasi enkripsi database sebelum AppDatabase dibuat.
/// Jika kunci enkripsi tersedia, file database terenkripsi akan didekripsi
/// ke lokasi kerja untuk digunakan Drift.
Future<void> _initializeDatabaseEncryption() async {
  final prefs = await _getPrefs();
  final encryptionKey = prefs.getString('database_encryption_key');

  if (encryptionKey != null && encryptionKey.isNotEmpty) {
    await AppDatabase.setEncryptionKey(encryptionKey);
    await AppDatabase.initializeEncryptedDatabase();
  }
}

/// Ambil instance SharedPreferences
Future<SharedPreferences> _getPrefs() async {
  return SharedPreferences.getInstance();
}

/// Hapus database SQLite lama jika ada (untuk migrasi skema v1 -> v2).
/// Data lama akan dihapus dan dibuat ulang seed baru dengan businessId + storeId.
Future<void> _deleteDatabaseIfNeeded() async {
  final homeDir = Platform.environment['HOME'] ?? '/tmp';

  // Hapus file database lama (plaintext di .pos_database)
  final oldDbDir = Directory(p.join(homeDir, '.pos_database'));
  final oldDbFile = File(p.join(oldDbDir.path, 'pos_database.sqlite'));
  if (oldDbFile.existsSync()) {
    await oldDbFile.delete();
    debugPrint('Database lama dihapus: ${oldDbFile.path}');
  }

  // Hapus file kerja jika ada (plaintext di .pos_database_working)
  final workingDbDir = Directory(p.join(homeDir, '.pos_database_working'));
  final workingDbFile = File(p.join(workingDbDir.path, 'pos_database.sqlite'));
  if (workingDbFile.existsSync()) {
    await workingDbFile.delete();
    debugPrint('Database kerja dihapus: ${workingDbFile.path}');
  }
}

/// Amankan database saat aplikasi pindah background / close.
/// Enkripsi file kerja kembali ke `.enc` dan hapus file plaintext.
Future<void> secureDatabaseOnExit() async {
  await AppDatabase.secureDatabaseAtRest();
}

/// Widget observer untuk lifecycle aplikasi.
/// - Saat app pindah background/inactive/paused: enkripsi database ke `.enc`
/// - Saat app kembali ke foreground/resume: dekripsi database dari `.enc`
class _DatabaseLifecycleObserver extends StatefulWidget {
  final Widget child;

  const _DatabaseLifecycleObserver({required this.child});

  @override
  State<_DatabaseLifecycleObserver> createState() =>
      _DatabaseLifecycleObserverState();
}

class _DatabaseLifecycleObserverState extends State<_DatabaseLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App pindah ke background — enkripsi database untuk proteksi at-rest
        secureDatabaseOnExit();
        break;
      case AppLifecycleState.resumed:
        // App kembali ke foreground — dekripsi database untuk digunakan
        _restoreDatabase();
        break;
      case AppLifecycleState.detached:
        // App ditutup — enkripsi database
        secureDatabaseOnExit();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Dekripsi database dari `.enc` ke lokasi kerja saat app resume
  Future<void> _restoreDatabase() async {
    if (!AppDatabase.isEncryptionEnabled) return;

    final encryptedPath = AppDatabase.encryptedDatabasePath();
    final workingPath = AppDatabase.databasePath();

    // Hapus file working yang mungkin ada (dari crash sebelumnya)
    final workingFile = File(workingPath);
    if (workingFile.existsSync()) {
      await workingFile.delete();
    }

    // Dekripsi dari `.enc`
    await EncryptedDatabaseManager.prepareDatabaseForUse(
      encryptedDbPath: encryptedPath,
      workingDbPath: workingPath,
      encryptionKey: AppDatabase.encryptionKey!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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
          _DatabaseLifecycleObserver(
            child: _ConnectivityWatcher(child: child ?? const SizedBox.shrink()),
          ),
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/database/sync_registry.dart';
import 'shared/providers/core_providers.dart';

/// Inisialisasi Supabase dari berkas .env (bos mengisi di sana).
Future<bool> _initSupabase() async {
  // Coba baca .env dari beberapa lokasi karena working directory
  // bisa berbeda saat flutter run di desktop/linux.
  final candidates = <String>[
    '.env',
    '${Directory.current.path}/.env',
    '${Directory(Directory.current.path).parent.path}/.env',
  ];

  for (final candidate in candidates) {
    try {
      final f = File(candidate);
      if (!f.existsSync()) continue;

      String? url;
      String? anonKey;
      for (final line in f.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq <= 0) continue;
        final key = trimmed.substring(0, eq).trim();
        final value = trimmed.substring(eq + 1).trim();
        if (key == 'SUPABASE_URL') url = value;
        if (key == 'SUPABASE_ANON_KEY') anonKey = value;
      }

      if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
        await Supabase.initialize(url: url, publishableKey: anonKey);
        debugPrint('🏴‍☠️ Supabase TERHUBUNG ke awan — mode online aktif.');
        return true;
      }
    } catch (_) {
      // Coba kandidat berikutnya
    }
  }

  debugPrint(
    '🏴‍☠️ Supabase TIDAK terhubung — jalan dalam mode offline-only. '
    'Isi SUPABASE_URL & SUPABASE_ANON_KEY di file .env.',
  );
  return false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (mode offline-only jika .env belum diisi)
  await _initSupabase();

  // Initialize database singleton BEFORE runApp to avoid multiple instances
  final db = initializeDatabase();

  // Register sync metas once at app startup
  registerAllSyncMetas(db);

  runApp(const ProviderScope(child: PosApp()));
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
      title: AppLocalizations.of(context)?.appDisplayName ?? 'POSku',
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

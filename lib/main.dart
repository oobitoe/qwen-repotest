import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/network/supabase_config.dart';
import 'core/database/sync_registry.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

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

    return MaterialApp.router(
      title: AppLocalizations.of(context)?.appDisplayName ?? 'POSku',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeModeOverride ?? themeMode,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
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
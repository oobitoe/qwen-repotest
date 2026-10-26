import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/network/supabase_config.dart';
import 'shared/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: PosApp()));
}

class PosApp extends ConsumerWidget {
  const PosApp({super.key, this.themeModeOverride});

  /// Override mode tema (dipakai pada pengujian agar deterministik).
  final ThemeMode? themeModeOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'POSku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeModeOverride ?? ThemeMode.system,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
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

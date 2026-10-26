import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/sync_dao.dart';
import '../../core/database/sync_engine.dart';
import '../../core/database/sync_registry.dart';
import '../../core/network/supabase_config.dart';

/// Dependency injection terpusat berbasis Riverpod.
final databaseProvider = Provider<AppDatabase>((ref) {
  registerAllSyncMetas();
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Akses helper sinkronisasi generik (outbox + LWW).
final syncDaoProvider = Provider<SyncableDao>(
  (ref) => SyncableDao(ref.watch(databaseProvider)),
);

const uuid = Uuid();

/// Penyedia UUID agar mudah di-mock pada pengujian.
final uuidProvider = Provider<Uuid>((ref) => uuid);

/// True bila Supabase tersedia (kredensial terisi & SDK aktif).
final supabaseAvailableProvider = Provider<bool>(
  (ref) => SupabaseConfig.instance.isValid && SupabaseConfig.client != null,
);

/// Transport sinkronisasi: Supabase bila tersedia, selain itu in-memory
/// (mode offline-only — push/pull tidak pernah benar-benar dilakukan).
final syncTransportProvider = Provider<SyncTransport>((ref) {
  final client = SupabaseConfig.client;
  if (SupabaseConfig.instance.isValid && client != null) {
    return SupabaseSyncTransport(client);
  }
  return InMemorySyncTransport(online: false);
});

/// Engine sinkronisasi global (push outbox + pull + backoff).
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    transport: ref.watch(syncTransportProvider),
    onlineChecker: () => _lastConnectivity,
  );
  engine.startPeriodic();
  ref.onDispose(engine.dispose);
  return engine;
});

bool _lastConnectivity = true;

/// Stream status koneksi perangkat.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) => Connectivity().onConnectivityChanged,
);

/// Status sinkronisasi hidup untuk UI (badge, kartu, dsb).
final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final engine = ref.watch(syncEngineProvider);
  yield engine.current;
  yield* engine.statusStream;
});

/// Trigger manual "Sinkronkan sekarang" dari UI.
/// Trigger manual "Sinkronkan sekarang" dari UI (berterima WidgetRef
/// maupun Ref biasa karena keduanya meng-expose read()).
Future<void> runManualSync(Object refHolder) {
  final r = refHolder as dynamic;
  return r.read(syncEngineProvider).syncNow() as Future<void>;
}

/// Pembaruan status koneksi global (dipanggil dari main.dart listener).
void updateConnectivity(List<ConnectivityResult> results) {
  _lastConnectivity =
      results.any((r) => r != ConnectivityResult.none);
}

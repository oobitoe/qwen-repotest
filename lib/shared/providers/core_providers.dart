import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/sync_dao.dart';
import '../../core/database/sync_engine.dart';

/// Global singleton database instance.
/// Dibuat sekali saat aplikasi start untuk menghindari multiple instances warning Drift.
late final AppDatabase _globalDatabase;

/// Inisialisasi database global (dipanggil dari main.dart sebelum runApp).
AppDatabase initializeDatabase() {
  _globalDatabase = AppDatabase();
  return _globalDatabase;
}

/// Dependency injection terpusat berbasis Riverpod.
/// Menggunakan global singleton untuk menghindari multiple database instances.
final databaseProvider = Provider<AppDatabase>((ref) {
  return _globalDatabase;
}, name: 'databaseProvider');

/// Akses helper sinkronisasi generik (outbox + LWW).
final syncDaoProvider = Provider<SyncableDao>((ref) => SyncableDao(ref.watch(databaseProvider)));

const uuid = Uuid();

/// Penyedia UUID agar mudah di-mock pada pengujian.
final uuidProvider = Provider<Uuid>((ref) => uuid);

/// Locale saat ini (id / en). Diubah dari halaman Settings.
final localeProvider = StateProvider<Locale>((ref) => const Locale('id', 'ID'));

/// Transport sinkronisasi: saat ini hanya in-memory (mode offline-only).
/// Integrasi PocketBase akan ditambahkan nanti.
final syncTransportProvider = Provider<SyncTransport>((ref) {
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

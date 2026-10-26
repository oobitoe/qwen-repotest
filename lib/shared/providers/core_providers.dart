import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import '../../core/database/sync_dao.dart';
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

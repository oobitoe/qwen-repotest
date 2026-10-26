import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';

/// Dependency injection terpusat berbasis Riverpod.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

const uuid = Uuid();

/// Penyedia UUID agar mudah di-mock pada pengujian.
final uuidProvider = Provider<Uuid>((ref) => uuid);

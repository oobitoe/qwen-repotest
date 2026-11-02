import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../core/network/pocketbase_client.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/application/auth_controller.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Status proses setup pertama kali.
///
/// - `initial`: belum diproses
/// - `checking`: sedang memeriksa
/// - `needsSetup`: siap dan perlu setup (businesses kosong + online + PB reachable)
/// - `ready`: siap tapi tidak perlu setup (businesses sudah punya data)
/// - `error`: gagal periksa atau error lain
enum SetupStatus { initial, checking, needsSetup, ready, error }

class SetupState {
  const SetupState({
    this.status = SetupStatus.initial,
    this.needsSetup = false,
    this.needsFirstOwner = false,
    this.error,
    this.online = false,
    this.pocketbaseReachable = false,
  });

  final SetupStatus status;
  final bool needsSetup;
  /// Apakah setup pertama kali perlu membuat akun Owner pertama (belum ada user sama sekali).
  final bool needsFirstOwner;
  final String? error;
  final bool online;
  final bool pocketbaseReachable;

  SetupState copyWith({
    SetupStatus? status,
    bool? needsSetup,
    bool? needsFirstOwner,
    String? error,
    bool? online,
    bool? pocketbaseReachable,
  }) {
    return SetupState(
      status: status ?? this.status,
      needsSetup: needsSetup ?? this.needsSetup,
      needsFirstOwner: needsFirstOwner ?? this.needsFirstOwner,
      error: error ?? this.error,
      online: online ?? this.online,
      pocketbaseReachable: pocketbaseReachable ?? this.pocketbaseReachable,
    );
  }
}

/// Controller untuk Setup / First-Run.
///
/// Tangani:
/// 1. Deteksi apakah tabel `businesses` kosong (belum pernah setup).
/// 2. Verifikasi koneksi online + PocketBase reachable sebelum setup diperbolehkan.
/// 3. Simpan bisnis & toko ke Drift lokal, enqueue ke `sync_queue`.
/// 4. Tandai `setup_completed` di `sync_metadata`.
class SetupController extends Notifier<SetupState> {
  @override
  SetupState build() {
    return const SetupState(status: SetupStatus.checking);
  }

  AppDatabase get db => ref.read(databaseProvider);

  SyncableDao get dao => SyncableDao(db);

  /// Cek apakah aplikasi perlu setup pertama kali.
  /// Panggil saat aplikasi pertama kali dijalankan.
  ///
  /// Alur:
  /// 1. Periksa tabel `businesses` — jika sudah ada isi, setup tidak diperlukan.
  /// 2. Jika kosong, periksa koneksi internet.
  /// 3. Jika online, periksa apakah PocketBase reachable.
  /// 4. Jika tidak terhubung (offline / PB unreachable), tampilkan error.
  /// 5. Jika terhubung, tandai siap untuk setup.
  Future<void> checkFirstRun() async {
    state = const SetupState(status: SetupStatus.checking);

    try {
      // 1. Cek apakah sudah pernah setup (businesses kosong?)
      final businessCount = await _countBusinesses();
      final setupCompleted = await _isSetupCompleted();
      final needsSetup = businessCount == 0 || !setupCompleted;

      // Jika tidak perlu setup bisnis, langsung siap
      if (!needsSetup) {
        // Tapi cek apakah sudah ada Owner — kalau belum, perlu daftar Owner pertama
        final localOwnerCount = await _countLocalOwners();
        final needsFirstOwner = localOwnerCount == 0;

        state = SetupState(
          status: SetupStatus.ready,
          needsSetup: false,
          needsFirstOwner: needsFirstOwner,
          online: true,
          pocketbaseReachable: true,
        );
        return;
      }

      // 2. Periksa koneksi internet
      await Future.delayed(const Duration(milliseconds: 500));
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(online: isOnline);

      if (!isOnline) {
        state = state.copyWith(
          status: SetupStatus.error,
          error:
              'Koneksi internet tidak terdeteksi. Setup pertama kali membutuhkan koneksi online.',
          needsSetup: true,
        );
        return;
      }

      // 3. Periksa PocketBase reachable
      await Future.delayed(const Duration(milliseconds: 500));
      final pbReachable = await PocketBaseClient.client.healthCheck();
      state = state.copyWith(pocketbaseReachable: pbReachable);

      if (!pbReachable) {
        state = state.copyWith(
          status: SetupStatus.error,
          error:
              'Database server tidak dapat dihubungi. Setup pertama kali membutuhkan koneksi ke Database server.',
          needsSetup: true,
        );
        return;
      }

      // 4. Sudah online + PB reachable → cek apakah sudah ada Owner (PB + lokal)
      final existingBusinessId = await _getFirstBusinessId();
      final pbUserCount =
          await _countPocketBaseUsers(businessId: existingBusinessId);
      final localOwnerCount = await _countLocalOwners();
      final needsFirstOwner = pbUserCount == 0 && localOwnerCount == 0;

      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(
        status: SetupStatus.needsSetup,
        needsSetup: true,
        needsFirstOwner: needsFirstOwner,
        online: isOnline,
        pocketbaseReachable: pbReachable,
      );
    } catch (e) {
      state = SetupState(
        status: SetupStatus.error,
        error: 'Gagal memeriksa status setup: $e',
        needsSetup: true,
      );
    }
  }

  /// Daftarkan Owner pertama saat setup pertama kali.
  /// Role selalu Owner dan tidak dapat diubah.
  Future<void> registerFirstOwner({
    required String email,
    required String password,
    required String fullName,
    String? businessId, // Bisnis yang memiliki Owner ini (WAJIB untuk setup)
  }) async {
    state = state.copyWith(status: SetupStatus.checking, error: null);
    try {
      await ref.read(authProvider.notifier).registerFirstOwner(
            email,
            password,
            fullName,
            businessId: businessId,
          );

      // Tandai setup selesai di sync_metadata
      await _setSetupCompleted(true);

      state = const SetupState(
        status: SetupStatus.ready,
        needsSetup: false,
        needsFirstOwner: false,
        online: true,
        pocketbaseReachable: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: SetupStatus.error,
        error: 'Gagal daftar Owner pertama: $e',
        needsFirstOwner: true,
      );
    }
  }

  /// Jumlah bisnis di tabel lokal.
  Future<int> _countBusinesses() async {
    final count = await (db.selectOnly(db.businesses)
          ..addColumns([db.businesses.id.count()]))
        .getSingle();
    return count.read(db.businesses.id.count()) ?? 0;
  }

  /// Jumlah user dengan role Owner di tabel Profils lokal (Drift).
  /// Digunakan untuk menentukan apakah sudah ada Owner pertama atau belum.
  Future<int> _countLocalOwners() async {
    final owners = await (db.select(db.profiles)
          ..where((t) => t.role.equals('owner')))
        .get();
    return owners.length;
  }

  /// Ambil ID bisnis pertama yang ada di tabel lokal.
  /// Digunakan untuk filter user per bisnis di PocketBase.
  Future<String?> _getFirstBusinessId() async {
    final row = await (db.select(db.businesses)..limit(1)).getSingleOrNull();
    return row?.id;
  }

  /// Publik wrapper untuk [_getFirstBusinessId] agar diakses dari UI.
  Future<String?> getFirstBusinessId() => _getFirstBusinessId();

  /// Jumlah user di PocketBase collection `users`.
  /// Jika [businessId] disediakan, hanya hitung user milik bisnis tersebut.
  Future<int> _countPocketBaseUsers({String? businessId}) async {
    final filter = businessId != null ? 'businessId = $businessId' : null;
    final page = await PocketBaseClient.instance
        .collection('users')
        .getList(page: 1, perPage: 1, filter: filter);
    return page.totalItems;
  }

  /// Simpan bisnis dan toko pertama kali, lalu tandai setup selesai.
  /// Semua data disimpan ke Drift lokal dan di-enqueue ke `sync_queue` untuk
  /// dikirim ke PocketBase saat sinkronisasi berjalan.
  /// Return businessId yang baru dibuat.
  Future<String> completeSetup({
    required String businessName,
    required String businessCurrency,
    required String businessTimezone,
    required String storeName,
    required String? storeAddress,
    required String? storePhone,
  }) async {
    state = state.copyWith(status: SetupStatus.checking, error: null);

    try {
      final uuid = const Uuid();
      final businessId = uuid.v4();
      final storeId = uuid.v4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      await db.transaction(() async {
        // --- Simpan ke tabel `businesses` (Drift) ---
        await db.into(db.businesses).insert(
          BusinessesCompanion.insert(
            id: businessId,
            name: businessName,
            currency: Value(businessCurrency),
            timezone: Value(businessTimezone),
            createdAt: Value(DateTime.fromMillisecondsSinceEpoch(now)),
            updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(now)),
            version: Value(1),
            syncStatus: const Value('pending'),
          ),
        );

        // --- Simpan ke tabel `stores` (Drift) ---
        await db.into(db.stores).insert(
          StoresCompanion.insert(
            id: storeId,
            businessId: businessId,
            name: storeName,
            address: Value(storeAddress),
            phone: Value(storePhone),
            createdAt: Value(DateTime.fromMillisecondsSinceEpoch(now)),
            updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(now)),
            version: Value(1),
            syncStatus: const Value('pending'),
          ),
        );

        // --- Enqueue ke `sync_queue` untuk push ke PocketBase ---
        await dao.enqueue(
          entityType: 'business',
          entityId: businessId,
          operation: 'upsert',
          payload: {
            'id': businessId,
            'name': businessName,
            'currency': businessCurrency,
            'timezone': businessTimezone,
            'created_at': now,
            'updated_at': now,
            'version': 1,
            'sync_status': 'pending',
          },
          nextRetryAt: DateTime.now().toUtc(),
        );

        await dao.enqueue(
          entityType: 'store',
          entityId: storeId,
          operation: 'upsert',
          payload: {
            'id': storeId,
            'business_id': businessId,
            'name': storeName,
            'address': storeAddress,
            'phone': storePhone,
            'created_at': now,
            'updated_at': now,
            'version': 1,
            'sync_status': 'pending',
          },
          nextRetryAt: DateTime.now().toUtc(),
        );
      });

      // Tandai setup selesai di sync_metadata
      await _setSetupCompleted(true);

      state = state.copyWith(
        status: SetupStatus.ready,
        needsSetup: false,
        needsFirstOwner: true, // Belum ada Owner, harus daftar Owner pertama
        online: true,
        pocketbaseReachable: true,
      );

      return businessId;
    } catch (e) {
      state = state.copyWith(
        status: SetupStatus.error,
        error: 'Gagal menyimpan setup: $e',
      );
      rethrow;
    }
  }

  /// Cek apakah `setup_completed` sudah ditandai di sync_metadata.
  Future<bool> _isSetupCompleted() async {
    final row = await (db.select(db.syncMetadata)
          ..where((t) => t.key.equals('setup_completed')))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  /// Simpan flag setup_completed ke sync_metadata.
  Future<void> _setSetupCompleted(bool value) async {
    await db.into(db.syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion.insert(
        key: 'setup_completed',
        value: value ? 'true' : 'false',
      ),
    );
  }
}

final setupControllerProvider =
    NotifierProvider<SetupController, SetupState>(SetupController.new);

/// Provider untuk mengetahui apakah perlu setup pertama kali.
final needsSetupProvider = Provider<bool>((ref) {
  final state = ref.watch(setupControllerProvider);
  return state.needsSetup;
});
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

/// Data pengaturan toko/bisnis yang diambil dari tabel bisnis, toko, dan
/// tabel pengaturan (business_settings / store_settings / tax_settings).
class StoreSetting {
  const StoreSetting({
    required this.businessId,
    required this.storeId,
    required this.businessName,
    required this.storeName,
    required this.storeAddress,
    required this.storePhone,
    required this.currency,
    required this.timezone,
    required this.taxRate,
    required this.taxName,
    required this.printerName,
    required this.printerEnabled,
    required this.printerAddress,
  });

  final String businessId;
  final String storeId;
  final String businessName;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String currency;
  final String timezone;
  final double taxRate;
  final String taxName;
  final String printerName;
  final bool printerEnabled;
  final String printerAddress; // Bluetooth MAC/address printer

  StoreSetting copyWith({
    String? businessId,
    String? storeId,
    String? businessName,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? currency,
    String? timezone,
    double? taxRate,
    String? taxName,
    String? printerName,
    bool? printerEnabled,
    String? printerAddress,
  }) {
    return StoreSetting(
      businessId: businessId ?? this.businessId,
      storeId: storeId ?? this.storeId,
      businessName: businessName ?? this.businessName,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      taxRate: taxRate ?? this.taxRate,
      taxName: taxName ?? this.taxName,
      printerName: printerName ?? this.printerName,
      printerEnabled: printerEnabled ?? this.printerEnabled,
      printerAddress: printerAddress ?? this.printerAddress,
    );
  }
}

/// Repository untuk mengelola pengaturan toko/bisnis secara lokal (Drift).
class StoreSettingsRepository {
  StoreSettingsRepository(this._db);

  final AppDatabase _db;

  /// Ambil pengaturan toko aktif. Jika belum ada, buat default.
  Future<StoreSetting> getSettings() async {
    // Ambil bisnis pertama
    final businesses = await (_db.select(_db.businesses)).get();
    if (businesses.isEmpty) {
      throw StateError('Belum ada data bisnis. Silakan buat bisnis terlebih dahulu.');
    }
    final business = businesses.first;

    // Ambil toko pertama yang terkait bisnis
    final stores = await (_db.select(_db.stores)
          ..where((t) => t.businessId.equals(business.id)))
        .get();
    final store = stores.isNotEmpty ? stores.first : null;

    // Ambil tax settings aktif
    final taxRows = await (_db.select(_db.taxSettings)
          ..where((t) => t.isActive.equals(true)))
        .get();
    final taxRate = taxRows.isNotEmpty ? taxRows.first.rate : 0.0;
    final taxName = taxRows.isNotEmpty ? taxRows.first.name : 'PPN';

    // Ambil dari business_settings & store_settings
    final printerName = await _getSettingValue('printer_name', 'Thermal Printer');
    final printerEnabledStr = await _getSettingValue('printer_enabled', 'true');
    final printerEnabled = printerEnabledStr == 'true';
    final printerAddress = await _getSettingValue('printer_address', '');

    return StoreSetting(
      businessId: business.id,
      storeId: store?.id ?? business.id,
      businessName: business.name,
      storeName: store?.name ?? business.name,
      storeAddress: store?.address ?? '',
      storePhone: store?.phone ?? '',
      currency: business.currency,
      timezone: business.timezone,
      taxRate: taxRate,
      taxName: taxName,
      printerName: printerName,
      printerEnabled: printerEnabled,
      printerAddress: printerAddress,
    );
  }

  /// Ambil nilai setting dari tabel BusinessSettings atau StoreSettings.
  Future<String> _getSettingValue(String key, String defaultValue) async {
    // Coba di business_settings dulu
    final bizRows = await (_db.select(_db.businessSettings)
          ..where((t) => t.key.equals(key) & t.businessId.equals('local')))
        .get();
    if (bizRows.isNotEmpty) return bizRows.first.value;

    // Coba di store_settings
    final storeRows = await (_db.select(_db.storeSettings)
          ..where((t) => t.key.equals(key) & t.storeId.equals('local')))
        .get();
    if (storeRows.isNotEmpty) return storeRows.first.value;

    return defaultValue;
  }

  /// Simpan pengaturan toko. Membuat/update bisnis, toko, dan setting terkait.
  Future<void> saveSettings(StoreSetting setting) async {
    await _db.transaction(() async {
      // Update atau insert bisnis
      final existingBiz = await (_db.select(_db.businesses)
            ..where((t) => t.id.equals(setting.businessId)))
          .getSingleOrNull();

      if (existingBiz == null) {
        await _db.into(_db.businesses).insert(
          BusinessesCompanion(
            id: Value(setting.businessId),
            name: Value(setting.businessName),
            currency: Value(setting.currency),
            timezone: Value(setting.timezone),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            version: Value(1),
            syncStatus: const Value('pending'),
          ),
        );
      } else {
        await (_db.update(_db.businesses)..where((t) => t.id.equals(setting.businessId)))
            .write(BusinessesCompanion(
          name: Value(setting.businessName),
          currency: Value(setting.currency),
          timezone: Value(setting.timezone),
          updatedAt: Value(DateTime.now()),
          version: Value(existingBiz.version + 1),
          syncStatus: const Value('pending'),
        ));
      }

      // Update atau insert toko
      final existingStore = await (_db.select(_db.stores)
            ..where((t) => t.id.equals(setting.storeId)))
          .getSingleOrNull();

      if (existingStore == null) {
        await _db.into(_db.stores).insert(
          StoresCompanion(
            id: Value(setting.storeId),
            businessId: Value(setting.businessId),
            name: Value(setting.storeName),
            address: Value(setting.storeAddress),
            phone: Value(setting.storePhone),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            version: Value(1),
            syncStatus: const Value('pending'),
          ),
        );
      } else {
        await (_db.update(_db.stores)..where((t) => t.id.equals(setting.storeId)))
            .write(StoresCompanion(
          name: Value(setting.storeName),
          address: Value(setting.storeAddress),
          phone: Value(setting.storePhone),
          updatedAt: Value(DateTime.now()),
          version: Value(existingStore.version + 1),
          syncStatus: const Value('pending'),
        ));
      }

      // Simpan printer settings ke store_settings
      await _upsertPrinterSetting(
        storeId: setting.storeId,
        key: 'printer_name',
        value: setting.printerName,
      );
      await _upsertPrinterSetting(
        storeId: setting.storeId,
        key: 'printer_enabled',
        value: setting.printerEnabled ? 'true' : 'false',
      );
      await _upsertPrinterSetting(
        storeId: setting.storeId,
        key: 'printer_address',
        value: setting.printerAddress,
      );
    });
  }

  /// Upsert printer setting ke tabel store_settings.
  Future<void> _upsertPrinterSetting({
    required String storeId,
    required String key,
    required String value,
  }) async {
    final existing = await (_db.select(_db.storeSettings)
          ..where((t) => t.key.equals(key) & t.storeId.equals(storeId)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.storeSettings).insert(
        StoreSettingsCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          storeId: Value(storeId),
          key: Value(key),
          value: Value(value),
          updatedAt: Value(DateTime.now()),
          version: Value(1),
          syncStatus: const Value('pending'),
        ),
      );
    } else {
      await (_db.update(_db.storeSettings)..where((t) => t.id.equals(existing.id)))
          .write(StoreSettingsCompanion(
        value: Value(value),
        updatedAt: Value(DateTime.now()),
        version: Value(existing.version + 1),
        syncStatus: const Value('pending'),
      ));
    }
  }

  /// Update tax rate.
  Future<void> updateTaxRate({required double rate, required String name}) async {
    final existing = await (_db.select(_db.taxSettings)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.taxSettings).insert(
        TaxSettingsCompanion(
          id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
          businessId: Value('local'),
          name: Value(name),
          rate: Value(rate),
          isActive: Value(true),
          createdAt: Value(DateTime.now()),
          version: Value(1),
          syncStatus: const Value('pending'),
        ),
      );
    } else {
      await (_db.update(_db.taxSettings)..where((t) => t.id.equals(existing.id)))
          .write(TaxSettingsCompanion(
        name: Value(name),
        rate: Value(rate),
        version: Value(existing.version + 1),
        syncStatus: const Value('pending'),
      ));
    }
  }
}

final storeSettingsRepositoryProvider = Provider<StoreSettingsRepository>((ref) {
  return StoreSettingsRepository(ref.watch(databaseProvider));
});

/// Provider untuk settings toko (future).
final storeSettingsProvider = FutureProvider<StoreSetting>((ref) async {
  final repo = ref.watch(storeSettingsRepositoryProvider);
  return repo.getSettings();
});

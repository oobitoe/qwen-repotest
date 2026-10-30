library pocketbase_transport;

/// Transport sinkronisasi berbasis PocketBase.
///
/// Menerapkan kontrak [SyncTransport] agar [SyncEngine] dapat push outbox
/// dan pull perubahan dari server PocketBase yang sudah berjalan.
///
/// Setiap `entityType` di antrean outbox dipetakan ke nama koleksi PocketBase
/// melalui [_collectionMap]. Pastikan koleksi tersebut sudah dibuat di
/// PocketBase Admin UI sebelum sinkronisasi dijalankan.
import 'package:pocketbase/pocketbase.dart';

import '../../core/database/sync_engine.dart';
import 'pocketbase_client.dart';

/// Format tanggal yang dipahami PocketBase filter:
/// `2024-01-15 10:30:00.000Z` (ISO8601-ish dengan spasi sebagai pemisah).
String _pbDate(DateTime d) {
  final utc = d.toUtc();
  return '${utc.year}-${_pad2(utc.month)}-${_pad2(utc.day)} '
      '${_pad2(utc.hour)}:${_pad2(utc.minute)}:${_pad2(utc.second)}.'
      '${utc.millisecond.toString().padLeft(3, '0')}Z';
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// Pemetaan tipe entitas (dari `sync_queue.entityType`) ke nama koleksi
/// PocketBase. Kunci harus sama dengan nilai `entityType` yang di-enqueue
/// oleh [SyncableDao]; nilai harus nama koleksi di PocketBase.
const Map<String, String> _collectionMap = {
  // Organisasi & pengguna
  'business': 'businesses',
  'store': 'stores',
  'profile': 'profiles',
  // Produk
  'category': 'categories',
  'unit': 'units',
  'product': 'products',
  'stock_movement': 'stock_movements',
  'product_variant': 'product_variants',
  'product_barcode': 'product_barcodes',
  'product_price': 'product_prices',
  'product_image': 'product_images',
  // Pelanggan & Supplier
  'supplier': 'suppliers',
  'customer': 'customers',
  'customer_address': 'customer_addresses',
  // Inventaris
  'stock_adjustment': 'stock_adjustments',
  'stock_adjustment_item': 'stock_adjustment_items',
  'stock_opname': 'stock_opnames',
  'stock_opname_item': 'stock_opname_items',
  'stock_transfer': 'stock_transfers',
  'stock_transfer_item': 'stock_transfer_items',
  // Penjualan (POS)
  'sale': 'sales',
  'sale_item': 'sale_items',
  'sale_payment': 'sale_payments',
  'sale_return': 'sale_returns',
  'sale_return_item': 'sale_return_items',
  // Pembelian
  'purchase': 'purchases',
  'purchase_item': 'purchase_items',
  'purchase_payment': 'purchase_payments',
  'purchase_order': 'purchase_orders',
  'purchase_order_item': 'purchase_order_items',
  'purchase_return': 'purchase_returns',
  'purchase_return_item': 'purchase_return_items',
  // Keuangan
  'expense_category': 'expense_categories',
  'expense': 'expenses',
  'income_category': 'income_categories',
  'income': 'income_entries',
  'cash_register': 'cash_registers',
  'cash_session': 'cash_sessions',
  'cash_movement': 'cash_movements',
  'account': 'accounts',
  'account_transaction': 'account_transactions',
  'debt': 'debts',
  'debt_payment': 'debt_payments',
  'financial_adjustment': 'financial_adjustments',
  // Konfigurasi & akses
  'business_setting': 'business_settings',
  'store_setting': 'store_settings',
  'tax_setting': 'tax_settings',
  'payment_method_config': 'payment_methods_config',
  'device': 'devices',
  'role': 'roles',
  'permission': 'permissions',
  'role_permission': 'role_permissions',
  'business_member': 'business_members',
  'user_store_access': 'user_store_access',
  'sale_sequence': 'sale_sequences',
  'audit_log': 'audit_logs',
};

/// Implementasi [SyncTransport] untuk PocketBase.
class PocketBaseSyncTransport implements SyncTransport {
  PocketBaseSyncTransport([PocketBase? client])
      : _pb = client ?? PocketBaseClient.instance;

  final PocketBase _pb;

  @override
  Future<List<String>> push(List<OutboxItem> batch) async {
    final accepted = <String>[];
    for (final item in batch) {
      try {
        final collection = _collectionMap[item.entityType];
        if (collection == null) {
          // Tipe entitas tidak memiliki koleksi PocketBase — lewati.
          continue;
        }

        // Siapkan payload (hapus kolom metadata internal Drift).
        final payload = Map<String, dynamic>.from(item.payload);
        payload.remove('sync_status');
        payload.remove('version');
        payload.remove('created_at');
        payload.remove('updated_at');

        try {
          // Coba update record yang sudah ada di PocketBase.
          await _pb.collection(collection).update(item.entityId, body: payload);
        } on ClientException catch (e) {
          // 404 = record belum ada di server, buat baru.
          if (e.statusCode == 404) {
            await _pb.collection(collection).create(body: payload);
          } else {
            rethrow;
          }
        }
        accepted.add(item.id);
      } catch (e) {
        throw PocketBaseSyncException(
          'Gagal push ${item.entityType}/${item.entityId}: $e',
        );
      }
    }
    return accepted;
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> pull(DateTime since) async {
    final result = <String, List<Map<String, dynamic>>>{};
    final sinceStr = _pbDate(since);

    for (final entry in _collectionMap.entries) {
      try {
        final records = await _pb.collection(entry.value).getFullList(
          filter: 'updated > "$sinceStr"',
          sort: '-updated',
        );
        result[entry.key] = [
          for (final record in records)
            Map<String, dynamic>.from(record.toJson()),
        ];
      } on ClientException catch (e) {
        // Koleksi mungkin belum ada di server — treat sebagai kosong.
        if (e.statusCode == 400 || e.statusCode == 404) {
          result[entry.key] = [];
        } else {
          rethrow;
        }
      } catch (e) {
        throw PocketBaseSyncException(
          'Gagal pull koleksi ${entry.value}: $e',
        );
      }
    }
    return result;
  }
}

/// Exception yang dilempar ketika operasi PocketBase gagal.
class PocketBaseSyncException implements Exception {
  const PocketBaseSyncException(this.message);
  final String message;
  @override
  String toString() => 'PocketBaseSyncException: $message';
}

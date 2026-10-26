import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'inventory_entity.dart';

/// Repository inventaris: pergerakan stok, penyesuaian, dan opname.
class InventoryRepository {
  InventoryRepository(this._db, this._dao);

  final AppDatabase _db;
  final SyncableDao _dao;
  final Uuid _uuid = Uuid();

  /// Stream riwayat pergerakan stok.
  Stream<List<StockMovementEntity>> watchStockMovements({
    String? productId,
    int limit = 50,
  }) {
    final q = _db.select(_db.stockMovements);
    if (productId != null) {
      q.where((t) => t.productId.equals(productId));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    q.limit(limit);
    return q.watch().map((rows) {
      return [
        for (final r in rows)
          StockMovementEntity(
            id: r.id,
            productId: r.productId,
            type: r.type,
            quantity: r.quantity,
            balanceAfter: r.balanceAfter,
            referenceType: r.referenceType,
            referenceId: r.referenceId,
            note: r.note,
            createdBy: r.createdBy,
            createdAt: r.createdAt,
          ),
      ];
    });
  }

  /// Catat pergerakan stok dalam satu transaksi (atomic).
  /// Mengupdate stock cache di tabel products sekaligus mencatat movement.
  Future<void> recordMovement({
    required String productId,
    required String type,
    required double quantity,
    required String referenceType,
    required String referenceId,
    String? note,
    String? createdBy,
  }) async {
    await _db.transaction(() async {
      // Ambil stock saat ini
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(productId)))
          .getSingle();
      final newBalance = product.stock + quantity;

      // Simpan movement
      await _db.into(_db.stockMovements).insert(
        StockMovementsCompanion.insert(
          id: _uuid.v4(),
          productId: productId,
          type: type,
          quantity: quantity,
          balanceAfter: newBalance,
          referenceType: Value(referenceType),
          referenceId: Value(referenceId),
          note: Value(note),
          createdBy: Value(createdBy),
        ),
      );

      // Update stock cache di produk
      await _dao.upsertAndEnqueue(
        'product',
        {
          'stock': newBalance,
        },
        id: productId,
      );

      // Enqueue movement ke outbox
      await _dao.enqueue(
        entityType: 'stock_movement',
        entityId: _uuid.v4(),
        operation: 'upsert',
        payload: {
          'product_id': productId,
          'type': type,
          'quantity': quantity,
          'balance_after': newBalance,
          'reference_type': referenceType,
          'reference_id': referenceId,
          'note': note,
          'created_by': createdBy,
        },
      );
    });
  }

  /// Buat penyesuaian stok (stock adjustment) dengan item-item.
  Future<void> createAdjustment({
    required String referenceNumber,
    required List<AdjustmentItem> items,
    String? note,
    String? createdBy,
  }) async {
    await _db.transaction(() async {
      final adjustmentId = _uuid.v4();

      await _db.into(_db.stockAdjustments).insert(
        StockAdjustmentsCompanion.insert(
          id: adjustmentId,
          referenceNumber: referenceNumber,
          note: Value(note),
          createdBy: Value(createdBy),
        ),
      );

      for (final item in items) {
        await _db.into(_db.stockAdjustmentItems).insert(
          StockAdjustmentItemsCompanion.insert(
            id: _uuid.v4(),
            adjustmentId: adjustmentId,
            productId: item.productId,
            quantityBefore: item.quantityBefore,
            quantityAfter: item.quantityAfter,
            reason: Value(item.reason),
          ),
        );

        // Update stock produk
        await _dao.upsertAndEnqueue(
          'product',
          {
            'stock': item.quantityAfter,
          },
          id: item.productId,
        );

        // Catat movement
        await _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            id: _uuid.v4(),
            productId: item.productId,
            type: 'adjustment',
            quantity: item.quantityAfter - item.quantityBefore,
            balanceAfter: item.quantityAfter,
            referenceType: Value('adjustment'),
            referenceId: Value(adjustmentId),
            note: Value(item.reason ?? note),
            createdBy: Value(createdBy),
          ),
        );
      }

      // Enqueue adjustment
      await _dao.enqueue(
        entityType: 'stock_adjustment',
        entityId: adjustmentId,
        operation: 'upsert',
        payload: {
          'id': adjustmentId,
          'reference_number': referenceNumber,
          'note': note,
          'created_by': createdBy,
        },
      );
    });
  }

  /// Buat stock opname.
  Future<void> createOpname({
    required String referenceNumber,
    required List<OpnameItem> items,
    String? createdBy,
  }) async {
    await _db.transaction(() async {
      final opnameId = _uuid.v4();

      await _db.into(_db.stockOpnames).insert(
        StockOpnamesCompanion.insert(
          id: opnameId,
          referenceNumber: referenceNumber,
          status: Value('draft'),
          createdBy: Value(createdBy),
        ),
      );

      for (final item in items) {
        await _db.into(_db.stockOpnameItems).insert(
          StockOpnameItemsCompanion.insert(
            id: _uuid.v4(),
            opnameId: opnameId,
            productId: item.productId,
            systemStock: item.systemStock,
            countedStock: item.countedStock,
          ),
        );
      }

      await _dao.enqueue(
        entityType: 'stock_opname',
        entityId: opnameId,
        operation: 'upsert',
        payload: {
          'id': opnameId,
          'reference_number': referenceNumber,
          'status': 'draft',
          'created_by': createdBy,
        },
      );
    });
  }
}

/// Item penyesuaian stok.
class AdjustmentItem {
  const AdjustmentItem({
    required this.productId,
    required this.quantityBefore,
    required this.quantityAfter,
    this.reason,
  });

  final String productId;
  final double quantityBefore;
  final double quantityAfter;
  final String? reason;
}

/// Item stock opname.
class OpnameItem {
  const OpnameItem({
    required this.productId,
    required this.systemStock,
    required this.countedStock,
  });

  final String productId;
  final double systemStock;
  final double countedStock;
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(syncDaoProvider);
  return InventoryRepository(db, dao);
});

final stockMovementsProvider = StreamProvider<List<StockMovementEntity>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.watchStockMovements();
});

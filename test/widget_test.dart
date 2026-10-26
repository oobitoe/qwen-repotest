import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/sync_dao.dart';
import 'package:pos_app/core/database/sync_engine.dart';
import 'package:pos_app/core/database/sync_registry.dart';
import 'package:pos_app/features/dashboard/application/dashboard_repository.dart';
import 'package:pos_app/main.dart';
import 'package:pos_app/shared/providers/core_providers.dart';

void main() {
  setUpAll(registerAllSyncMetas);

  group('Smoke UI', () {
    testWidgets('aplikasi merender tanpa exception', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: PosApp(themeModeOverride: ThemeMode.light),
        ),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  group('DashboardRepository (DB in-memory)', () {
    late AppDatabase db;
    late DashboardRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DashboardRepository(db);
    });
    tearDown(() => db.close());

    Future<void> seedProduct({
      required String id,
      required double stock,
      required double minStock,
      double sellPrice = 10000,
      double costPrice = 6000,
    }) {
      return db.into(db.products).insert(ProductsCompanion.insert(
            id: id,
            businessId: 'biz-1',
            sku: 'SKU-$id',
            name: 'Produk $id',
            sellPrice: Value(sellPrice),
            costPrice: Value(costPrice),
            minStock: Value(minStock),
            stock: Value(stock),
            isActive: const Value(true),
          ));
    }

    Future<void> seedSale({
      required String id,
      required double total,
      DateTime? at,
    }) {
      return db.into(db.sales).insert(SalesCompanion.insert(
            id: id,
            invoiceNumber: 'INV-$id',
            subtotal: Value(total),
            total: Value(total),
            paid: Value(total),
            createdAt: Value(at ?? DateTime.now()),
          ));
    }

    test('snapshot kosong menghasilkan nol & 14 titik deret', () async {
      final snap = await repo.load();
      expect(snap.todayRevenue, 0);
      expect(snap.todayTx, 0);
      expect(snap.productCount, 0);
      expect(snap.salesSeries.length, 14);
      expect(snap.lowStock, isEmpty);
      expect(snap.activities, isEmpty);
    });

    test('agregasi penjualan hari ini, produk, dan stok menipis', () async {
      await seedProduct(id: 'p1', stock: 2, minStock: 5); // menipis
      await seedProduct(id: 'p2', stock: 0, minStock: 3); // habis
      await seedProduct(id: 'p3', stock: 50, minStock: 5); // aman
      await seedSale(id: 's1', total: 25000);
      await seedSale(id: 's2', total: 15000);
      // Penjualan kemarin (tidak masuk todayRevenue, masuk deret)
      await seedSale(
        id: 's3',
        total: 10000,
        at: DateTime.now().subtract(const Duration(days: 1)),
      );

      final snap = await repo.load();
      expect(snap.todayRevenue, 40000);
      expect(snap.todayTx, 2);
      expect(snap.productCount, 3);
      expect(snap.lowStock.map((e) => e.productId).toSet(), {'p1', 'p2'});
      expect(snap.salesSeries.any((p) => p.total > 0), isTrue);
      expect(snap.activities.length, greaterThanOrEqualTo(2));
      // delta vs kemarin (10000 -> 40000) = +300%
      expect(snap.todayRevenueDelta, closeTo(300.0, 0.01));
    });

    test('penjualan soft-deleted tidak dihitung', () async {
      await seedSale(id: 's1', total: 100000);
      await db.customUpdate(
        'UPDATE sales SET deleted_at = ? WHERE id = ?',
        variables: [
          Variable.withDateTime(DateTime.now().toUtc()),
          Variable.withString('s1'),
        ],
      );
      final snap = await repo.load();
      expect(snap.todayRevenue, 0);
    });
  });

  group('SyncableDao + SyncEngine (outbox & LWW)', () {
    late AppDatabase db;
    late SyncableDao dao;

    setUp(() {
      registerAllSyncMetas();
      db = AppDatabase(NativeDatabase.memory());
      dao = SyncableDao(db);
    });
    tearDown(() => db.close());

    Future<void> insertProduct(String id, {double price = 1000}) =>
        db.into(db.products).insert(ProductsCompanion.insert(
              id: id,
              businessId: 'biz-1',
              sku: 'SKU-$id',
              name: 'Produk $id',
              sellPrice: Value(price),
              costPrice: const Value(500),
              minStock: const Value(5),
              stock: const Value(20),
            ));

    test('upsertAndEnqueue menulis baris + antrian outbox', () async {
      await insertProduct('p1');
      await dao.upsertAndEnqueue('product', {'name': 'Diubah'}, id: 'p1');

      expect(await dao.countPendingQueue(), 1);
      final items = await dao.dueQueueItems();
      expect(items.single.operation, SyncOperations.upsert);
      expect(items.single.payload['name'], 'Diubah');
      expect(items.single.payload['id'], 'p1');
      expect(await dao.currentVersion('product', 'p1'), 1);

      final row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.name, 'Diubah');
      expect(row.syncStatus, SyncStatuses.pending);
    });

    test('softDeleteAndEnqueue menandai deleted_at + operasi delete', () async {
      await insertProduct('p1');
      await dao.softDeleteAndEnqueue('product', 'p1');
      final items = await dao.dueQueueItems();
      expect(items.single.operation, SyncOperations.delete);
      final row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('markQueueItemFailed menjadwalkan backoff lalu failed permanen',
        () async {
      await insertProduct('p1');
      await dao.upsertAndEnqueue('product', {'name': 'x'}, id: 'p1');
      final item = (await dao.dueQueueItems()).single;

      await dao.markQueueItemFailed(
          item.id, 'network down', DateTime.now().toUtc(), 1);
      final reread = (await dao.dueQueueItems()).single;
      expect(reread.retryCount, 1);
      expect(await dao.countPendingQueue(), 1);

      await dao.markQueueItemFailed(item.id, 'still down',
          DateTime.now().toUtc(), AppConstants.maxSyncRetries);
      expect(await dao.countFailedQueue(), 1);
    });

    test(
        'applyRemoteUpsert: remote lebih baru menang, lokal pending dilindungi',
        () async {
      await insertProduct('p1');
      final base = DateTime.utc(2026, 10, 1, 12);
      await db.customUpdate(
        'UPDATE products SET updated_at = ?, version = 1, sync_status = ? '
        'WHERE id = ?',
        variables: [
          Variable.withDateTime(base),
          Variable.withString(SyncStatuses.synced),
          Variable.withString('p1'),
        ],
      );

      // Remote lebih baru -> diterapkan.
      final applied = await dao.applyRemoteUpsert('product', {
        'id': 'p1',
        'name': 'Remote Baru',
        'updated_at': base.add(const Duration(hours: 1)).toIso8601String(),
        'version': 2,
      });
      expect(applied, isTrue);
      var row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.name, 'Remote Baru');
      expect(row.syncStatus, SyncStatuses.synced);

      // Remote lama + lokal pending -> lokal menang.
      await dao.upsertAndEnqueue('product', {'name': 'Edit Lokal'}, id: 'p1');
      final rejected = await dao.applyRemoteUpsert('product', {
        'id': 'p1',
        'name': 'Remote Lama',
        'updated_at': base.toIso8601String(),
        'version': 9,
      });
      expect(rejected, isFalse);
      row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.name, 'Edit Lokal');
    });

    test('engine push sukses menandai outbox done & entitas synced', () async {
      await insertProduct('p1');
      await dao.upsertAndEnqueue('product', {'name': 'Ke server'}, id: 'p1');

      final transport = InMemorySyncTransport(online: true);
      final engine = SyncEngine(db: db, transport: transport);
      await engine.syncNow();

      expect(transport.pushed, hasLength(1));
      expect(transport.pushed.single.entityId, 'p1');
      expect(await dao.countPendingQueue(), 0);
      final row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.syncStatus, SyncStatuses.synced);
      await engine.dispose();
    });

    test('engine offline tetap stabil, status offline, data lokal utuh',
        () async {
      await insertProduct('p1');
      await dao.upsertAndEnqueue('product', {'name': 'Lokal saja'}, id: 'p1');

      final transport = InMemorySyncTransport(online: false);
      final engine = SyncEngine(db: db, transport: transport);
      await engine.syncNow();

      expect(engine.current.phase, SyncPhase.offline);
      expect(engine.current.pendingCount, 1);
      final row = await (db.select(db.products)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.name, 'Lokal saja');
      await engine.dispose();
    });

    test('engine pull menerapkan data remote baru', () async {
      final transport = InMemorySyncTransport(online: true);
      transport.remoteData['category'] = [
        {
          'id': 'c-remote',
          'business_id': 'biz-1',
          'name': 'Kategori Remote',
          'is_active': true,
          'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
          'updated_at': DateTime.utc(2026, 10, 2).toIso8601String(),
          'version': 1,
        },
      ];
      final engine = SyncEngine(db: db, transport: transport);
      await engine.syncNow();

      final cats = await db.select(db.categories).get();
      expect(cats.map((c) => c.name), contains('Kategori Remote'));
      await engine.dispose();
    });
  });

  group('Providers', () {
    test('supabaseAvailableProvider false saat tanpa kredensial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(supabaseAvailableProvider), isFalse);
    });
  });
}

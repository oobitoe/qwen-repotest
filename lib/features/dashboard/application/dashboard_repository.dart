import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Titik data grafik penjualan harian.
typedef SalesPoint = ({DateTime date, double total, int txCount});

/// Item daftar stok menipis / habis.
typedef LowStockItem = ({
  String productId,
  String name,
  String sku,
  double stock,
  double minStock,
});

/// Entri aktivitas terbaru (gabungan penjualan, pengeluaran).
typedef ActivityEntry = ({
  DateTime at,
  String title,
  String subtitle,
  double amount,
  ActivityKind kind,
});

enum ActivityKind { sale, expense }

/// Agregat lengkap untuk halaman dashboard. Semua dihitung lokal-first
/// dari SQLite (Drift) — tidak ada jaringan pada jalur baca.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.todayRevenue,
    required this.todayRevenueDelta,
    required this.todayTx,
    required this.todayProfit,
    required this.productCount,
    required this.pendingSyncCount,
    required this.failedSyncCount,
    required this.salesSeries,
    required this.lowStock,
    required this.activities,
  });

  final double todayRevenue;
  final double todayRevenueDelta; // % vs kemarin
  final int todayTx;
  final double todayProfit;
  final int productCount;
  final int pendingSyncCount;
  final int failedSyncCount;
  final List<SalesPoint> salesSeries; // 14 hari terakhir
  final List<LowStockItem> lowStock;
  final List<ActivityEntry> activities;
}

/// Repository lokal-first untuk data dashboard (agregasi read-only).
class DashboardRepository {
  const DashboardRepository(this._db);

  final AppDatabase _db;

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Snapshot agregat dashboard.
  Future<DashboardSnapshot> load() async {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final windowStart = todayStart.subtract(const Duration(days: 13));

    // --- Pendapatan hari ini & kemarin ---------------------------------
    Future<double> revenueBetween(DateTime from, DateTime to) async {
      final q = _db.selectOnly(_db.sales)
        ..addColumns([_db.sales.total.sum()])
        ..where(_db.sales.createdAt.isBiggerOrEqualValue(from) &
            _db.sales.createdAt.isSmallerThanValue(to) &
            _db.sales.deletedAt.isNull() &
            _db.sales.status.equals('completed'));
      final row = await q.getSingle();
      return row.read(_db.sales.total.sum()) ?? 0;
    }

    final todayRevenue = await revenueBetween(todayStart, now.add(minutes: 1));
    final ystRevenue = await revenueBetween(yesterdayStart, todayStart);
    final todayRevenueDelta = ystRevenue == 0
        ? (todayRevenue > 0 ? 100.0 : 0.0)
        : (todayRevenue - ystRevenue) / ystRevenue * 100.0;

    final txQ = _db.selectOnly(_db.sales)
      ..addColumns([_db.sales.id.count()])
      ..where(_db.sales.createdAt.isBiggerOrEqualValue(todayStart) &
          _db.sales.deletedAt.isNull() &
          _db.sales.status.equals('completed'));
    final todayTx = (await txQ.getSingle()).read(_db.sales.id.count()) ?? 0;

    // --- Laba kotor hari ini (penjualan - HPP item terjual) ------------
    final itemsToday = await (_db.select(_db.saleItems)
          ..where(_db.saleItems.createdAt.isBiggerOrEqualValue(todayStart) &
              _db.saleItems.deletedAt.isNull()))
        .get();
    var cogs = 0.0;
    if (itemsToday.isNotEmpty) {
      final costRows = await (_db.select(_db.products)
            ..where(_db.products.id.isIn(
                itemsToday.map((i) => i.productId).toSet())))
          .get();
      final costById = {for (final p in costRows) p.id: p.costPrice};
      cogs = itemsToday.fold<double>(
          0, (s, i) => s + i.quantity * (costById[i.productId] ?? 0));
    }
    final todayProfit = todayRevenue - cogs;

    // --- Jumlah produk aktif --------------------------------------------
    final prodQ = _db.selectOnly(_db.products)
      ..addColumns([_db.products.id.count()])
      ..where(_db.products.isActive.equals(true) &
          _db.products.deletedAt.isNull());
    final productCount =
        (await prodQ.getSingle()).read(_db.products.id.count()) ?? 0;

    // --- Antrian sync -----------------------------------------------------
    final pendingQ = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.status.isNotIn([SyncQueueStatuses.done]));
    final failedQ = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.id.count()])
      ..where(_db.syncQueue.status.equals(SyncQueueStatuses.failed));
    final pendingSync =
        (await pendingQ.getSingle()).read(_db.syncQueue.id.count()) ?? 0;
    final failedSync =
        (await failedQ.getSingle()).read(_db.syncQueue.id.count()) ?? 0;

    // --- Deret penjualan 14 hari -------------------------------------------
    final recent = await (_db.select(_db.sales)
          ..where(_db.sales.createdAt.isBiggerOrEqualValue(windowStart) &
              _db.sales.deletedAt.isNull() &
              _db.sales.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    final byDay = <String, (double, int)>{};
    for (final r in recent) {
      final d = r.createdAt;
      final key = '${d.year}-${d.month}-${d.day}';
      final cur = byDay[key] ?? (0.0, 0);
      byDay[key] = (cur.$1 + r.total, cur.$2 + 1);
    }
    final series = <SalesPoint>[
      for (var i = 0; i < 14; i++)
        () {
          final day = windowStart.add(Duration(days: i));
          final v = byDay['${day.year}-${day.month}-${day.day}'] ?? (0.0, 0);
          return (date: day, total: v.$1, txCount: v.$2);
        }(),
    ];

    // --- Stok menipis --------------------------------------------------------
    final lowRows = await (_db.select(_db.products)
          ..where((_db.products.stock.lowerOrEqual(_db.products.minStock) &
                  _db.products.stock.isBiggerThanValue(0)) |
              _db.products.stock.equals(0))
          ..where(_db.products.isActive.equals(true) &
              _db.products.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.stock)])
          ..limit(8))
        .get();
    final lowStock = [
      for (final p in lowRows)
        (
          productId: p.id,
          name: p.name,
          sku: p.sku,
          stock: p.stock,
          minStock: p.minStock,
        ),
    ];

    // --- Aktivitas terbaru ----------------------------------------------------
    final activityEntries = <ActivityEntry>[];
    final saleActs = await (_db.select(_db.sales)
          ..where(_db.sales.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(6))
        .get();
    for (final s in saleActs) {
      activityEntries.add((
        at: s.createdAt,
        title: s.invoiceNumber,
        subtitle: s.customerNameSnapshot == null
            ? 'Penjualan · ${s.paymentMethod}'
            : 'Penjualan · ${s.customerNameSnapshot}',
        amount: s.total,
        kind: ActivityKind.sale,
      ));
    }
    final expActs = await (_db.select(_db.expenses)
          ..where(_db.expenses.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(3))
        .get();
    for (final e in expActs) {
      activityEntries.add((
        at: e.createdAt,
        title: e.description,
        subtitle: 'Pengeluaran · ${e.paymentMethod}',
        amount: -e.amount,
        kind: ActivityKind.expense,
      ));
    }
    activityEntries.sort((a, b) => b.at.compareTo(a.at));

    return DashboardSnapshot(
      todayRevenue: todayRevenue,
      todayRevenueDelta: todayRevenueDelta,
      todayTx: todayTx,
      todayProfit: todayProfit,
      productCount: productCount,
      pendingSyncCount: pendingSync,
      failedSyncCount: failedSync,
      salesSeries: series,
      lowStock: lowStock,
      activities: activityEntries.take(8).toList(growable: false),
    );
  }
}

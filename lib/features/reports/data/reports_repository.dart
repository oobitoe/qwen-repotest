import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

/// Represents a report type for categorization.
enum ReportType {
  sales,
  purchases,
  inventory,
  financial,
  cashFlow,
  profitLoss,
  topProducts,
  topCategories,
  paymentMethods,
  customerSales,
  supplierPurchases,
}

/// Parameter untuk filtering laporan.
class ReportFilter {
  const ReportFilter({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.productId,
    this.customerId,
    this.supplierId,
    this.paymentMethod,
    this.storeId,
    this.cashierId,
    required this.businessId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? productId;
  final String? customerId;
  final String? supplierId;
  final String? paymentMethod;
  final String? storeId;
  final String? cashierId;
  final String businessId;

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? productId,
    String? customerId,
    String? supplierId,
    String? paymentMethod,
    String? storeId,
    String? cashierId,
    String? businessId,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      productId: productId ?? this.productId,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      storeId: storeId ?? this.storeId,
      cashierId: cashierId ?? this.cashierId,
      businessId: businessId ?? this.businessId,
    );
  }
}

/// Base class untuk data laporan.
abstract class ReportData {
  const ReportData();
}

/// Data untuk laporan penjualan per periode.
class SalesReportData extends ReportData {
  const SalesReportData({
    required this.period,
    required this.totalSales,
    required this.totalTransactions,
    required this.averageTransaction,
    required this.grossRevenue,
    required this.netRevenue,
    required this.totalDiscount,
    required this.totalTax,
    required this.cogs,
    required this.grossProfit,
  });

  final String period;
  final double totalSales;
  final int totalTransactions;
  final double averageTransaction;
  final double grossRevenue;
  final double netRevenue;
  final double totalDiscount;
  final double totalTax;
  final double cogs;
  final double grossProfit;
}

/// Data untuk top products.
class TopProductReportData extends ReportData {
  const TopProductReportData({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.categoryName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  final String productId;
  final String productName;
  final String sku;
  final String categoryName;
  final int quantitySold;
  final double totalRevenue;
  final double totalProfit;
}

/// Data untuk laporan stok.
class StockReportData extends ReportData {
  const StockReportData({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.categoryName,
    required this.currentStock,
    required this.minStock,
    required this.costPrice,
    required this.sellPrice,
    required this.stockValue,
    required this.status,
  });

  final String productId;
  final String productName;
  final String sku;
  final String categoryName;
  final double currentStock;
  final double minStock;
  final double costPrice;
  final double sellPrice;
  final double stockValue;
  final String status; // 'normal', 'low', 'out'
}

/// Data untuk laporan arus kas.
class CashFlowReportData extends ReportData {
  const CashFlowReportData({
    required this.period,
    required this.cashIn,
    required this.cashOut,
    required this.netCashFlow,
    required this.openingBalance,
    required this.closingBalance,
  });

  final String period;
  final double cashIn;
  final double cashOut;
  final double netCashFlow;
  final double openingBalance;
  final double closingBalance;
}

/// Data untuk laporan laba rugi.
class ProfitLossReportData extends ReportData {
  const ProfitLossReportData({
    required this.period,
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.otherIncome,
    required this.netProfit,
  });

  final String period;
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double operatingExpenses;
  final double otherIncome;
  final double netProfit;
}

/// Repository untuk laporan.
class ReportsRepository {
  ReportsRepository(this._db);

  final AppDatabase _db;

  /// Laporan penjualan per hari/minggu/bulan.
  Future<List<SalesReportData>> getSalesReport(
    ReportFilter filter, {
    required String businessId,
    required String storeId,
  }) async {
    // Query sales filtered by businessId dan storeId
    final sales = await _db.select(_db.sales)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.storeId.equals(storeId));

    if (filter.startDate != null) {
      sales.where((t) => t.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      sales.where((t) => t.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }
    if (filter.cashierId != null) {
      sales.where((t) => t.cashierId.equals(filter.cashierId!));
    }

    final saleRows = await sales.get();

    // Group by date
    final Map<String, SalesReportData> grouped = {};

    for (final sale in saleRows) {
      // Fetch sale items for this sale
      final items = await _db.select(_db.saleItems)
        ..where((t) => t.saleId.equals(sale.id))
        ..where((t) => t.businessId.equals(businessId))
        ..where((t) => t.storeId.equals(storeId));

      final itemRows = await items.get();

      final dateKey = _formatPeriod(sale.createdAt, filter);

      final existing = grouped[dateKey];
      if (existing == null) {
        final totalCogs = itemRows.fold<double>(
          0,
          (sum, item) => sum + item.costPrice * item.quantity,
        );
        final totalProfit = itemRows.fold<double>(
          0,
          (sum, item) => sum + (item.unitPrice - item.costPrice) * item.quantity,
        );

        grouped[dateKey] = SalesReportData(
          period: dateKey,
          totalSales: sale.total,
          totalTransactions: 1,
          averageTransaction: sale.total,
          grossRevenue: sale.subtotal,
          netRevenue: sale.total,
          totalDiscount: sale.discount,
          totalTax: sale.tax,
          cogs: totalCogs,
          grossProfit: totalProfit - sale.discount,
        );
      } else {
        final totalCogs = itemRows.fold<double>(
          0,
          (sum, item) => sum + item.costPrice * item.quantity,
        );
        final totalProfit = itemRows.fold<double>(
          0,
          (sum, item) => sum + (item.unitPrice - item.costPrice) * item.quantity,
        );

        grouped[dateKey] = SalesReportData(
          period: dateKey,
          totalSales: existing.totalSales + sale.total,
          totalTransactions: existing.totalTransactions + 1,
          averageTransaction: (existing.totalSales + sale.total) /
              (existing.totalTransactions + 1),
          grossRevenue: existing.grossRevenue + sale.subtotal,
          netRevenue: existing.netRevenue + sale.total,
          totalDiscount: existing.totalDiscount + sale.discount,
          totalTax: existing.totalTax + sale.tax,
          cogs: existing.cogs + totalCogs,
          grossProfit: existing.grossProfit + totalProfit - sale.discount,
        );
      }
    }

    return grouped.values.toList()
      ..sort((a, b) => a.period.compareTo(b.period));
  }

  /// Top produk terjual.
  Future<List<TopProductReportData>> getTopProductsReport(
    ReportFilter filter, {
    required String businessId,
    required String storeId,
    int limit = 20,
  }) async {
    // Query sale items filtered by businessId dan storeId
    final items = await _db.select(_db.saleItems)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.storeId.equals(storeId));

    if (filter.startDate != null) {
      items.where((t) => _db.sales.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      items.where((t) => _db.sales.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }

    // Join with sales for date filter
    items.join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleItems.saleId)),
    ]);

    final itemRows = await items.get();

    // Fetch products and categories in batch
    final productIds = itemRows.map((i) => i.productId).toSet().toList();
    final products = <String, Map<String, dynamic>>{};
    for (final pid in productIds) {
      final p = await _db.select(_db.products)
        ..where((t) => t.id.equals(pid));
      final pRow = await p.getSingleOrNull();
      if (pRow != null) {
        products[pid] = {
          'sku': pRow.sku,
          'name': pRow.name,
          'categoryId': pRow.categoryId,
        };
      }
    }

    final categoryIds = products.values
        .map((p) => p['categoryId'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final categories = <String, String>{};
    for (final cid in categoryIds) {
      final c = await _db.select(_db.categories)
        ..where((t) => t.id.equals(cid));
      final cRow = await c.getSingleOrNull();
      if (cRow != null) {
        categories[cid] = cRow.name;
      }
    }

    final Map<String, TopProductReportData> grouped = {};

    for (final item in itemRows) {
      final p = products[item.productId];
      final productName = p?['name'] ?? '';
      final sku = p?['sku'] ?? '';
      final categoryId = p?['categoryId'];
      final categoryName = categoryId != null ? categories[categoryId] ?? 'Tanpa Kategori' : 'Tanpa Kategori';

      final key = item.productId;
      final existing = grouped[key];
      final revenue = item.lineTotal;
      final profit = (item.unitPrice - item.costPrice) * item.quantity;

      if (existing == null) {
        grouped[key] = TopProductReportData(
          productId: item.productId,
          productName: productName,
          sku: sku,
          categoryName: categoryName,
          quantitySold: item.quantity.toInt(),
          totalRevenue: revenue,
          totalProfit: profit,
        );
      } else {
        grouped[key] = TopProductReportData(
          productId: item.productId,
          productName: productName,
          sku: sku,
          categoryName: categoryName,
          quantitySold: existing.quantitySold + item.quantity.toInt(),
          totalRevenue: existing.totalRevenue + revenue,
          totalProfit: existing.totalProfit + profit,
        );
      }
    }

    final result = grouped.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return result.take(limit).toList();
  }

  /// Laporan stok (produk dengan stok rendah/habis).
  Future<List<StockReportData>> getStockReport(
    ReportFilter filter, {
    required String businessId,
    required String storeId,
  }) async {
    final query = _db.select(_db.products)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.storeId.equals(storeId));

    if (filter.categoryId != null) {
      query.where((t) => t.categoryId.equals(filter.categoryId!));
    }

    // Only active products
    query.where((t) => t.isActive.equals(true));

    final rows = await query.get();

    // Fetch categories
    final categoryIds = rows
        .map((r) => r.categoryId)
        .whereType<String>()
        .toSet()
        .toList();
    final categories = <String, String>{};
    for (final cid in categoryIds) {
      final c = await _db.select(_db.categories)
        ..where((t) => t.id.equals(cid));
      final cRow = await c.getSingleOrNull();
      if (cRow != null) {
        categories[cid] = cRow.name;
      }
    }

    return rows.map((row) {
      final categoryName = row.categoryId != null
          ? categories[row.categoryId] ?? 'Tanpa Kategori'
          : 'Tanpa Kategori';

      String status;
      if (row.stock <= 0) {
        status = 'out';
      } else if (row.stock <= row.minStock) {
        status = 'low';
      } else {
        status = 'normal';
      }

      return StockReportData(
        productId: row.id,
        productName: row.name,
        sku: row.sku,
        categoryName: categoryName,
        currentStock: row.stock,
        minStock: row.minStock,
        costPrice: row.costPrice,
        sellPrice: row.sellPrice,
        stockValue: row.stock * row.costPrice,
        status: status,
      );
    }).toList()
      ..sort((a, b) {
        // Sort by status: out > low > normal
        final order = {'out': 0, 'low': 1, 'normal': 2};
        return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
      });
  }

  /// Laporan arus kas.
  Future<List<CashFlowReportData>> getCashFlowReport(
    ReportFilter filter, {
    required String businessId,
    required String storeId,
  }) async {
    // This would aggregate cash_movements, expenses, income, sales payments
    // Simplified implementation
    return [];
  }

  /// Laporan laba rugi.
  Future<List<ProfitLossReportData>> getProfitLossReport(
    ReportFilter filter, {
    required String businessId,
    required String storeId,
  }) async {
    // This would calculate revenue, cogs, expenses, etc.
    // Simplified implementation
    return [];
  }

  String _formatPeriod(DateTime date, ReportFilter filter) {
    // Group by day/week/month based on date range
    final diff = (filter.endDate ?? DateTime.now())
        .difference(filter.startDate ?? date)
        .inDays;
    if (diff <= 31) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff <= 365) {
      return '${date.month}/${date.year}';
    } else {
      return '${date.year}';
    }
  }
}

/// Provider untuk ReportsRepository.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(databaseProvider));
});

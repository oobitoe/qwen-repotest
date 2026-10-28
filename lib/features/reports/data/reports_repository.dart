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
  Future<List<SalesReportData>> getSalesReport(ReportFilter filter) async {
    // Query penjualan dengan grouping berdasarkan periode
    final query = _db.select(_db.sales).join([
      innerJoin(_db.saleItems, _db.saleItems.saleId.equalsExp(_db.sales.id)),
    ]);

    // Apply filters
    if (filter.startDate != null) {
      query.where(_db.sales.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where(_db.sales.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }
    if (filter.cashierId != null) {
      query.where(_db.sales.cashierId.equals(filter.cashierId!));
    }

    final rows = await query.get();

    // Group by date (simplified - in production use SQL grouping)
    final Map<String, SalesReportData> grouped = {};

    for (final row in rows) {
      final sale = row.readTable(_db.sales);
      final item = row.readTable(_db.saleItems);
      final dateKey = _formatPeriod(sale.createdAt, filter);

      final existing = grouped[dateKey];
      if (existing == null) {
        grouped[dateKey] = SalesReportData(
          period: dateKey,
          totalSales: sale.total,
          totalTransactions: 1,
          averageTransaction: sale.total,
          grossRevenue: sale.subtotal,
          netRevenue: sale.total,
          totalDiscount: sale.discount,
          totalTax: sale.tax,
          cogs: item.costPrice * item.quantity,
          grossProfit: (item.unitPrice - item.costPrice) * item.quantity - sale.discount,
        );
      } else {
        grouped[dateKey] = SalesReportData(
          period: dateKey,
          totalSales: existing.totalSales + sale.total,
          totalTransactions: existing.totalTransactions + 1,
          averageTransaction: (existing.totalSales + sale.total) / (existing.totalTransactions + 1),
          grossRevenue: existing.grossRevenue + sale.subtotal,
          netRevenue: existing.netRevenue + sale.total,
          totalDiscount: existing.totalDiscount + sale.discount,
          totalTax: existing.totalTax + sale.tax,
          cogs: existing.cogs + (item.costPrice * item.quantity),
          grossProfit: existing.grossProfit + ((item.unitPrice - item.costPrice) * item.quantity - sale.discount),
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => a.period.compareTo(b.period));
  }

  /// Top produk terjual.
  Future<List<TopProductReportData>> getTopProductsReport(ReportFilter filter, {int limit = 20}) async {
    final query = _db.select(_db.saleItems).join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleItems.saleId)),
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.saleItems.productId)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ]);

    if (filter.startDate != null) {
      query.where(_db.sales.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where(_db.sales.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }

    final rows = await query.get();

    final Map<String, TopProductReportData> grouped = {};

    for (final row in rows) {
      final item = row.readTable(_db.saleItems);
      final product = row.readTableOrNull(_db.products);
      final category = row.readTableOrNull(_db.categories);

      final key = item.productId;
      final existing = grouped[key];
      final revenue = item.lineTotal;
      final profit = (item.unitPrice - item.costPrice) * item.quantity;

      if (existing == null) {
        grouped[key] = TopProductReportData(
          productId: item.productId,
          productName: item.productName,
          sku: product?.sku ?? '',
          categoryName: category?.name ?? 'Tanpa Kategori',
          quantitySold: item.quantity.toInt(),
          totalRevenue: revenue,
          totalProfit: profit,
        );
      } else {
        grouped[key] = TopProductReportData(
          productId: item.productId,
          productName: item.productName,
          sku: product?.sku ?? '',
          categoryName: category?.name ?? 'Tanpa Kategori',
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
  Future<List<StockReportData>> getStockReport(ReportFilter filter) async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ]);

    if (filter.categoryId != null) {
      query.where(_db.products.categoryId.equals(filter.categoryId!));
    }

    // Only active products
    query.where(_db.products.isActive.equals(true));

    final rows = await query.get();

    return rows.map((row) {
      final product = row.readTable(_db.products);
      final category = row.readTableOrNull(_db.categories);
      final stock = product.stock;
      final minStock = product.minStock;

      String status;
      if (stock <= 0) {
        status = 'out';
      } else if (stock <= minStock) {
        status = 'low';
      } else {
        status = 'normal';
      }

      return StockReportData(
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        categoryName: category?.name ?? 'Tanpa Kategori',
        currentStock: stock,
        minStock: minStock,
        costPrice: product.costPrice,
        sellPrice: product.sellPrice,
        stockValue: stock * product.costPrice,
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
  Future<List<CashFlowReportData>> getCashFlowReport(ReportFilter filter) async {
    // This would aggregate cash_movements, expenses, income, sales payments
    // Simplified implementation
    return [];
  }

  /// Laporan laba rugi.
  Future<List<ProfitLossReportData>> getProfitLossReport(ReportFilter filter) async {
    // This would calculate revenue, cogs, expenses, etc.
    // Simplified implementation
    return [];
  }

  String _formatPeriod(DateTime date, ReportFilter filter) {
    // Group by day/week/month based on date range
    final diff = (filter.endDate ?? DateTime.now()).difference(filter.startDate ?? date).inDays;
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
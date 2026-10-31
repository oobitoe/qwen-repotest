import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../app/theme/app_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/reports_repository.dart';

/// Halaman laporan keuangan dan operasional.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _updateDateControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  void _updateDateControllers() {
    final fmt = DateFormat('yyyy-MM-dd');
    _startDateCtrl.text = _startDate != null ? fmt.format(_startDate!) : '';
    _endDateCtrl.text = _endDate != null ? fmt.format(_endDate!) : '';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _updateDateControllers();
      });
    }
  }

  ReportFilter _buildFilter() {
    return ReportFilter(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.sales),
              Tab(text: l10n.products),
              Tab(text: l10n.inventory),
              Tab(text: l10n.financial),
            ],
          ),
           _DateFilterBar(
            startDateCtrl: _startDateCtrl,
            endDateCtrl: _endDateCtrl,
            onStartTap: () => _pickDate(isStart: true),
            onEndTap: () => _pickDate(isStart: false),
            onExportCSV: _exportCSV,
            onExportPDF: _exportPDF,
            l10n: l10n,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SalesReportTab(filter: _buildFilter(), l10n: l10n),
                _ProductsReportTab(filter: _buildFilter(), l10n: l10n),
                _InventoryReportTab(filter: _buildFilter(), l10n: l10n),
                _FinancialReportTab(filter: _buildFilter(), l10n: l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export CSV - Coming soon')),
    );
  }

  void _exportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export PDF - Coming soon')),
    );
  }
}

/// Bar filter tanggal.
class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.startDateCtrl,
    required this.endDateCtrl,
    required this.onStartTap,
    required this.onEndTap,
    required this.onExportCSV,
    required this.onExportPDF,
    required this.l10n,
  });

  final TextEditingController startDateCtrl;
  final TextEditingController endDateCtrl;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback onExportCSV;
  final VoidCallback onExportPDF;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: startDateCtrl,
              readOnly: true,
              onTap: onStartTap,
              decoration: InputDecoration(
                labelText: l10n.startDate,
                prefixIcon: const Icon(AppIcons.calendarMonthRounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: endDateCtrl,
              readOnly: true,
              onTap: onEndTap,
              decoration: InputDecoration(
                labelText: l10n.endDate,
                prefixIcon: const Icon(AppIcons.calendarMonthRounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
           FilledButton.icon(
            onPressed: onExportCSV,
            icon: const Icon(AppIcons.downloadRounded),
            label: Text(l10n.exportCSV),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onExportPDF,
            icon: const Icon(AppIcons.pictureAsPdfRounded),
            label: Text(l10n.exportPDF),
          ),
        ],
      ),
    );
  }
}

/// Tab laporan penjualan.
class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab({required this.filter, required this.l10n});

  final ReportFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(_salesReportProvider(filter));

    return reportAsync.when(
      data: (data) => _SalesReportContent(data: data, l10n: l10n),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

final _salesReportProvider = FutureProvider.family<List<SalesReportData>, ReportFilter>(
  (ref, filter) async {
    final repo = ref.watch(reportsRepositoryProvider);
    return repo.getSalesReport(filter);
  },
);

class _SalesReportContent extends StatelessWidget {
  const _SalesReportContent({required this.data, required this.l10n});

  final List<SalesReportData> data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (data.isEmpty) {
      return _EmptyState(
        icon: AppIcons.receiptLongRounded,
        message: l10n.noData,
      );
    }

    final totalSales = data.fold<double>(0, (sum, d) => sum + d.totalSales);
    final totalTx = data.fold<int>(0, (sum, d) => sum + d.totalTransactions);
    final totalProfit = data.fold<double>(0, (sum, d) => sum + d.grossProfit);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _SummaryCard(title: l10n.totalSales, value: fmt.format(totalSales), icon: AppIcons.paymentsRounded, color: AppTheme.success)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SummaryCard(title: l10n.transactions, value: '$totalTx', icon: AppIcons.receiptLongRounded, color: AppTheme.info)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SummaryCard(title: l10n.grossProfit, value: fmt.format(totalProfit), icon: AppIcons.trendingUpRounded, color: const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Chart
          _ChartCard(
            title: l10n.salesChart,
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (v, meta) => SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(NumberFormat.compact(locale: 'id_ID').format(v), style: theme.textTheme.labelSmall),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(data[i].period, style: theme.textTheme.labelSmall),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].totalSales)],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      barWidth: 3,
                      gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [theme.colorScheme.primary.withValues(alpha: 0.2), theme.colorScheme.primary.withValues(alpha: 0.02)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Data table
          _DataTableCard(
            title: l10n.detail,
            columns: [
              DataColumn(label: Text(l10n.period)),
              DataColumn(label: Text(l10n.revenue), numeric: true),
              DataColumn(label: Text(l10n.transactions), numeric: true),
              DataColumn(label: Text(l10n.avgTransaction), numeric: true),
              DataColumn(label: Text(l10n.grossProfit), numeric: true),
            ],
            rows: data.map((d) => DataRow(cells: [
              DataCell(Text(d.period)),
              DataCell(Text(fmt.format(d.totalSales))),
              DataCell(Text('${d.totalTransactions}')),
              DataCell(Text(fmt.format(d.averageTransaction))),
              DataCell(Text(fmt.format(d.grossProfit), style: TextStyle(color: d.grossProfit >= 0 ? AppTheme.success : AppTheme.error))),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}

/// Tab laporan produk.
class _ProductsReportTab extends ConsumerWidget {
  const _ProductsReportTab({required this.filter, required this.l10n});

  final ReportFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(_topProductsProvider(filter));

    return reportAsync.when(
      data: (data) => _ProductsReportContent(data: data, l10n: l10n),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

final _topProductsProvider = FutureProvider.family<List<TopProductReportData>, ReportFilter>(
  (ref, filter) async {
    final repo = ref.watch(reportsRepositoryProvider);
    return repo.getTopProductsReport(filter);
  },
);

class _ProductsReportContent extends StatelessWidget {
  const _ProductsReportContent({required this.data, required this.l10n});

  final List<TopProductReportData> data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (data.isEmpty) {
      return _EmptyState(icon: AppIcons.inventory2Rounded, message: l10n.noData);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _DataTableCard(
        title: l10n.topProducts,
        columns: [
          DataColumn(label: Text(l10n.product)),
          DataColumn(label: Text(l10n.category)),
          DataColumn(label: Text(l10n.qtySold), numeric: true),
          DataColumn(label: Text(l10n.revenue), numeric: true),
          DataColumn(label: Text(l10n.profit), numeric: true),
        ],
        rows: data.map((d) => DataRow(cells: [
          DataCell(Text(d.productName)),
          DataCell(Text(d.categoryName)),
          DataCell(Text('${d.quantitySold}')),
          DataCell(Text(fmt.format(d.totalRevenue))),
          DataCell(Text(fmt.format(d.totalProfit), style: TextStyle(color: d.totalProfit >= 0 ? AppTheme.success : AppTheme.error))),
        ])).toList(),
      ),
    );
  }
}

/// Tab laporan inventaris.
class _InventoryReportTab extends ConsumerWidget {
  const _InventoryReportTab({required this.filter, required this.l10n});

  final ReportFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(_stockReportProvider(filter));

    return reportAsync.when(
      data: (data) => _InventoryReportContent(data: data, l10n: l10n),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

final _stockReportProvider = FutureProvider.family<List<StockReportData>, ReportFilter>(
  (ref, filter) async {
    final repo = ref.watch(reportsRepositoryProvider);
    return repo.getStockReport(filter);
  },
);

class _InventoryReportContent extends StatelessWidget {
  const _InventoryReportContent({required this.data, required this.l10n});

  final List<StockReportData> data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (data.isEmpty) {
      return _EmptyState(icon: AppIcons.inventory2Rounded, message: l10n.noData);
    }

    final lowStock = data.where((d) => d.status != 'normal').length;
    final totalValue = data.fold<double>(0, (sum, d) => sum + d.stockValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(title: l10n.totalStockValue, value: fmt.format(totalValue), icon: AppIcons.accountBalanceRounded, color: AppTheme.info)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SummaryCard(title: l10n.lowStockItems, value: '$lowStock', icon: AppIcons.warningAmberRounded, color: AppTheme.warning)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _SummaryCard(title: l10n.totalProducts, value: '${data.length}', icon: AppIcons.inventory2Rounded, color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DataTableCard(
            title: l10n.stockDetail,
            columns: [
              DataColumn(label: Text(l10n.product)),
              DataColumn(label: Text(l10n.category)),
              DataColumn(label: Text(l10n.stock), numeric: true),
              DataColumn(label: Text(l10n.minStock), numeric: true),
              DataColumn(label: Text(l10n.stockValue), numeric: true),
              DataColumn(label: Text(l10n.status)),
            ],
            rows: data.map((d) => DataRow(cells: [
              DataCell(Text(d.productName)),
              DataCell(Text(d.categoryName)),
              DataCell(Text(d.currentStock.toStringAsFixed(0))),
              DataCell(Text(d.minStock.toStringAsFixed(0))),
              DataCell(Text(fmt.format(d.stockValue))),
              DataCell(_StatusChip(status: d.status)),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'out':
        color = AppTheme.error;
        label = 'Habis';
        break;
      case 'low':
        color = AppTheme.warning;
        label = 'Menipis';
        break;
      default:
        color = AppTheme.success;
        label = 'Normal';
    }
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

/// Tab laporan keuangan.
class _FinancialReportTab extends ConsumerWidget {
  const _FinancialReportTab({required this.filter, required this.l10n});

  final ReportFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profitLoss, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          _EmptyState(
            icon: AppIcons.analyticsRounded,
            message: l10n.comingSoon(l10n.profitLoss),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.cashFlow, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          _EmptyState(
            icon: AppIcons.accountBalanceRounded,
            message: l10n.comingSoon(l10n.cashFlow),
          ),
        ],
      ),
    );
  }
}

/// Summary card reusable.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 2),
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Chart card reusable.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Data table card reusable.
class _DataTableCard extends StatelessWidget {
  const _DataTableCard({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              headingRowColor: WidgetStateProperty.resolveWith((states) => theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              dataRowMinHeight: 40,
              dataRowMaxHeight: 48,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state reusable.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
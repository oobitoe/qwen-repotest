import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/responsive/responsive_layout.dart';
import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/database/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/dashboard_repository.dart';

/// Provider snapshot dashboard — baca dari SQLite lokal (lokal-first).
final dashboardSnapshotProvider = FutureProvider<DashboardSnapshot>((ref) async {
  final repo = DashboardRepository(ref.watch(databaseProvider));
  return repo.load();
});

/// Halaman dashboard profesional: sidebar bisa diciutkan (via shell),
/// kartu statistik, grafik penjualan, aktivitas terbaru, stok menipis,
/// indikator status sinkronisasi, animasi halus.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncStatusProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final role = ref.watch(currentRoleProvider);
    final isDesktop = context.isDesktop;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(isDesktop ? l10n.dashboard : l10n.appDisplayName),
            if (isDesktop) ...[
              const SizedBox(width: AppSpacing.md),
              _GreetingChip(role: role?.name ?? 'owner', l10n: l10n),
            ],
          ],
        ),
        actions: [
          if (!context.isMobile) ...[
            _SyncBadge(status: sync, l10n: l10n),
            const SizedBox(width: AppSpacing.sm),
          ],
          IconButton(
            tooltip: l10n.syncNow,
            onPressed: () => runManualSync(ref),
            icon: const Icon(AppIcons.sync),
          ),
          IconButton(
            tooltip: l10n.logout,
            onPressed: () =>
                ref.read(authProvider.notifier).signOut(),
            icon: const Icon(AppIcons.logout),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSnapshotProvider);
          await ref.read(dashboardSnapshotProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _intro,
                child: slideUp(_intro, _SyncBanner(l10n: l10n)),
              ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: snapshot.when(
                  loading: () => const _DashboardSkeleton(),
                  error: (e, st) => _ErrorState(
                    message: '$e',
                    onRetry: () =>
                        ref.invalidate(dashboardSnapshotProvider),
                    l10n: l10n,
                  ),
                  data: (data) => _DashboardBody(
                    data: data,
                    controller: _intro,
                    wide: context.isTablet || context.isDesktop,
                    l10n: l10n,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-quick-sale',
        onPressed: () {},
        backgroundColor: AppTheme.success,
        foregroundColor: Colors.white,
        icon: const Icon(AppIcons.pointOfSaleRounded),
        label: Text(
          l10n.newTransaction,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget slideUp(AnimationController c, Widget child) => AnimatedBuilder(
        animation: c,
        builder: (_, ch) => Transform.translate(
          offset: Offset(0, 24 * (1 - c.value)),
          child: Opacity(opacity: c.value, child: ch),
        ),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Banner status sinkronisasi (terlihat jelas di bagian atas dashboard)
// ---------------------------------------------------------------------------

class _SyncBanner extends ConsumerWidget {
  const _SyncBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider).valueOrNull;
    final pending = snapshot?.pendingSyncCount ?? 0;

    final (icon, color, label) = sync.when(
      loading: () => (AppIcons.cloudUploadOutlined,
          Theme.of(context).colorScheme.primary, l10n.syncNow),
      error: (_, __) => (AppIcons.cloudOffRounded, AppTheme.error,
          l10n.syncInterrupted),
      data: (s) => switch (s.phase) {
        SyncPhase.offline => (
            AppIcons.wifiOffRounded,
            AppTheme.warning,
            pending > 0
                ?             l10n.offlinePending(pending.toString())
                : l10n.offlineSaved),
        SyncPhase.syncing => (
            AppIcons.syncRounded,
            AppTheme.info,
            l10n.syncing((s.inFlight + s.pendingCount).toString())),
        SyncPhase.error => (
            AppIcons.errorOutlineRounded,
            AppTheme.error,
            l10n.syncError(s.message ?? l10n.retry)),
        SyncPhase.idle => (
            AppIcons.cloudDoneRounded,
            AppTheme.success,
            s.lastSyncAt == null
                ? l10n.syncReady
                : l10n.syncSynced(_ago(l10n, s.lastSyncAt!))),
      },
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.slow,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.98 + 0.02 * v, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (sync.valueOrNull?.phase == SyncPhase.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _ago(AppLocalizations l10n, DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return l10n.agoJustNow;
    if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes.toString());
    if (diff.inHours < 24) return l10n.agoHours(diff.inHours.toString());
    return DateFormat('d MMM, HH:mm').format(t.toLocal());
  }
}

// ---------------------------------------------------------------------------
// Isi dashboard: kartu statistik, grafik, daftar
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.data,
    required this.controller,
    required this.wide,
    required this.l10n,
  });

  final DashboardSnapshot data;
  final AnimationController controller;
  final bool wide;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _StatCard(
        index: 0,
        controller: controller,
        title: l10n.revenueToday,
        value: _idr(data.todayRevenue),
        delta: data.todayRevenueDelta,
        icon: AppIcons.paymentsRounded,
        color: AppTheme.success,
      ),
      _StatCard(
        index: 1,
        controller: controller,
        title: l10n.transactionsToday,
        value: '${data.todayTx}',
        delta: null,
        icon: AppIcons.receiptLongRounded,
        color: AppTheme.info,
        subtitle: l10n.subtitleInvoice,
      ),
      _StatCard(
        index: 2,
        controller: controller,
        title: l10n.grossProfitToday,
        value: _idr(data.todayProfit),
        delta: null,
        icon: AppIcons.trendingUpRounded,
        color: const Color(0xFF8B5CF6),
        subtitle: l10n.subtitleCogs,
      ),
      _StatCard(
        index: 3,
        controller: controller,
        title: l10n.activeProducts,
        value: '${data.productCount}',
        delta: null,
        icon: AppIcons.inventory2Rounded,
        color: AppTheme.warning,
        subtitle: data.lowStock.isNotEmpty
            ? l10n.lowStockCount(data.lowStock.length.toString())
            : l10n.stockSafe,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: context.isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: context.isDesktop ? 1.75 : 1.35,
          children: cards,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _SalesChartCard(series: data.salesSeries, l10n: l10n),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: _LowStockCard(items: data.lowStock, l10n: l10n)),
            ],
          )
        else ...[
          _SalesChartCard(series: data.salesSeries, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          _LowStockCard(items: data.lowStock, l10n: l10n),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ActivityCard(entries: data.activities, l10n: l10n),
      ],
    );
  }

  static String _idr(double v) => NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
      ).format(v);
}

// Kartu statistik dengan animasi masuk berjenjang & hover lift -------------

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.index,
    required this.controller,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.subtitle,
  });

  final int index;
  final AnimationController controller;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? delta;
  final String? subtitle;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: widget.controller,
      curve: Interval(
        (widget.index * 0.12).clamp(0.0, 0.7),
        (widget.index * 0.12 + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
              0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hover
                  ? widget.color.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const Spacer(),
                  if (widget.delta != null)
                    _DeltaChip(value: widget.delta!),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.value,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              if (widget.subtitle != null)
                Text(widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = up ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? AppIcons.arrowUpward : AppIcons.arrowDownward,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text('${value.abs().toStringAsFixed(0)}%',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Grafik penjualan 14 hari --------------------------------------------------

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({required this.series, required this.l10n});
  final List<SalesPoint> series;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = series.fold<double>(0, (m, p) => p.total > m ? p.total : m);
    final top = (maxV * 1.25).ceilToDouble();
    final fmt = NumberFormat.compact(locale: 'id_ID');

    return _SectionCard(
      title: l10n.chartSales,
      subtitle: l10n.chartSubtitle,
      trailing: Icon(AppIcons.insightsRounded,
          color: theme.colorScheme.primary),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: top == 0 ? 100 : top,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(fmt.format(v),
                        style: theme.textTheme.labelSmall),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= series.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('d/M').format(series[i].date),
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    LineTooltipItem(
                      '${DateFormat('d MMM').format(series[s.x.toInt()].date)}\n'
                      '${fmt.format(s.y)}',
                      TextStyle(
                        color: theme.colorScheme.inverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < series.length; i++)
                    FlSpot(i.toDouble(), series[i].total),
                ],
                isCurved: true,
                curveSmoothness: 0.28,
                barWidth: 3,
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ]),
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.25),
                      theme.colorScheme.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stok menipis ---------------------------------------------------------------

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.items, required this.l10n});
  final List<LowStockItem> items;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: l10n.lowStockTitle,
      subtitle: items.isEmpty ? null : '${items.length} produk',
      trailing: const Icon(AppIcons.warningAmberRounded,
          color: AppTheme.warning),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: [
                  const Icon(AppIcons.checkCircleOutlineRounded,
                      size: 36, color: AppTheme.success),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.allStockSafe,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : Column(
              children: [
                for (final it in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: (it.stock == 0
                              ? AppTheme.error
                              : AppTheme.warning)
                          .withValues(alpha: 0.15),
                      child: Icon(
                        it.stock == 0
                            ? AppIcons.removeShoppingCartRounded
                            : AppIcons.productionQuantityLimitsRounded,
                        size: 16,
                        color: it.stock == 0
                            ? AppTheme.error
                            : AppTheme.warning,
                      ),
                    ),
                    title: Text(it.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(it.sku,
                        style: theme.textTheme.bodySmall),
                    trailing: _StockPill(stock: it.stock, min: it.minStock, l10n: l10n),
                  ),
              ],
            ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock, required this.min, required this.l10n});
  final double stock;
  final double min;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final out = stock == 0;
    final color = out ? AppTheme.error : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        out ? l10n.outOfStock : '${stock.toInt()} / $min',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Aktivitas terbaru ------------------------------------------------------------

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entries, required this.l10n});
  final List<ActivityEntry> entries;
  final AppLocalizations l10n;

  static final _df = DateFormat('d MMM · HH:mm');
  static final _money =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: l10n.recentActivity,
      trailing: Icon(AppIcons.historyRounded,
          color: theme.colorScheme.primary),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(l10n.noActivity,
                  style: theme.textTheme.bodyMedium),
            )
          : Column(
              children: [
                for (final a in entries)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: (a.kind == ActivityKind.sale
                              ? AppTheme.success
                              : AppTheme.error)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        a.kind == ActivityKind.sale
                            ? AppIcons.shoppingBagRounded
                            : AppIcons.savingsRounded,
                        size: 16,
                        color: a.kind == ActivityKind.sale
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                    title: Text(a.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('${a.subtitle} · ${_df.format(a.at)}',
                        style: theme.textTheme.bodySmall),
                    trailing: Text(
                      _money.format(a.amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: a.amount >= 0
                            ? AppTheme.success
                            : AppTheme.error,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Komponen kerangka ------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: title),
                      if (subtitle != null)
                        TextSpan(
                          text: '  ·  $subtitle',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _GreetingChip extends StatelessWidget {
  const _GreetingChip({required this.role, required this.l10n});
  final String role;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 11
        ? l10n.greetingMorning
        : hour < 15
            ? l10n.greetingAfternoon
            : hour < 19
                ? l10n.greetingEvening
                : l10n.greetingNight;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(l10n.greetingRole(greet, role),
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SyncBadge extends ConsumerWidget {
  const _SyncBadge({required this.status, required this.l10n});
  final AsyncValue<SyncStatus> status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = status.valueOrNull;
    final (icon, color) = switch (s?.phase) {
      SyncPhase.offline => (AppIcons.cloudOffRounded, AppTheme.warning),
      SyncPhase.syncing => (AppIcons.syncRounded, AppTheme.info),
      SyncPhase.error => (AppIcons.errorOutlineRounded, AppTheme.error),
      _ => (AppIcons.cloudDoneRounded, AppTheme.success),
    };
    return Tooltip(
      message: switch (s?.phase) {
        SyncPhase.offline => l10n.offlineSaved,
        SyncPhase.syncing => 'Sinkronisasi berjalan',
        SyncPhase.error => l10n.syncInterrupted,
        _ => 'Terhubung & tersinkron',
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
    return Column(
      children: [
        Row(children: [Expanded(child: box(110)), const SizedBox(width: 16), Expanded(child: box(110))]),
        const SizedBox(height: 16),
        box(240),
        const SizedBox(height: 16),
        box(200),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry, required this.l10n});
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.bugReportOutlined, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/responsive/responsive_layout.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(isDesktop ? 'Dashboard' : 'POSku'),
            const SizedBox(width: AppSpacing.md),
            if (isDesktop) _GreetingChip(role: role?.name ?? 'owner'),
          ],
        ),
        actions: [
          _SyncBadge(status: sync),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Sinkronkan sekarang',
            onPressed: () => runManualSync(ref),
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () =>
                ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
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
                  child: slideUp(_intro, const _SyncBanner()),
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
                  ),
                  data: (data) => _DashboardBody(
                    data: data,
                    controller: _intro,
                    wide: context.isTablet || context.isDesktop,
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
        icon: const Icon(Icons.point_of_sale_rounded),
        label: Text(
          'Transaksi Baru',
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
  const _SyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStatusProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider).valueOrNull;
    final pending = snapshot?.pendingSyncCount ?? 0;

    final (icon, color, label) = sync.when(
      loading: () => (Icons.cloud_upload_outlined,
          Theme.of(context).colorScheme.primary, 'Menyiapkan sinkronisasi…'),
      error: (_, __) => (Icons.cloud_off_rounded, AppTheme.error,
          'Sinkronisasi terganggu'),
      data: (s) => switch (s.phase) {
        SyncPhase.offline => (
            Icons.wifi_off_rounded,
            AppTheme.warning,
            pending > 0
                ? 'Offline · $pending perubahan menunggu antrean'
                : 'Offline · semua data tersimpan lokal'),
        SyncPhase.syncing => (
            Icons.sync_rounded,
            AppTheme.info,
            'Sedang sinkronisasi… (${s.inFlight + s.pendingCount} item)'),
        SyncPhase.error => (
            Icons.error_outline_rounded,
            AppTheme.error,
            'Galat sync: ${s.message ?? 'coba lagi'}'),
        SyncPhase.idle => (
            Icons.cloud_done_rounded,
            AppTheme.success,
            s.lastSyncAt == null
                ? 'Siap · tersimpan lokal'
                : 'Tersinkron · terakhir ${_ago(s.lastSyncAt!)}'),
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

  static String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
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
  });

  final DashboardSnapshot data;
  final AnimationController controller;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _StatCard(
        index: 0,
        controller: controller,
        title: 'Pendapatan Hari Ini',
        value: _idr(data.todayRevenue),
        delta: data.todayRevenueDelta,
        icon: Icons.payments_rounded,
        color: AppTheme.success,
      ),
      _StatCard(
        index: 1,
        controller: controller,
        title: 'Transaksi Hari Ini',
        value: '${data.todayTx}',
        delta: null,
        icon: Icons.receipt_long_rounded,
        color: AppTheme.info,
        subtitle: 'invoice selesai',
      ),
      _StatCard(
        index: 2,
        controller: controller,
        title: 'Laba Kotor Hari Ini',
        value: _idr(data.todayProfit),
        delta: null,
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF8B5CF6),
        subtitle: 'setelah HPP',
      ),
      _StatCard(
        index: 3,
        controller: controller,
        title: 'Produk Aktif',
        value: '${data.productCount}',
        delta: null,
        icon: Icons.inventory_2_rounded,
        color: AppTheme.warning,
        subtitle: data.lowStock.isNotEmpty
            ? '${data.lowStock.length} perlu restok'
            : 'stok aman',
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
                child: _SalesChartCard(series: data.salesSeries),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: _LowStockCard(items: data.lowStock)),
            ],
          )
        else ...[
          _SalesChartCard(series: data.salesSeries),
          const SizedBox(height: AppSpacing.lg),
          _LowStockCard(items: data.lowStock),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ActivityCard(entries: data.activities),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
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
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
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
  const _SalesChartCard({required this.series});
  final List<SalesPoint> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = series.fold<double>(0, (m, p) => p.total > m ? p.total : m);
    final top = (maxV * 1.25).ceilToDouble();
    final fmt = NumberFormat.compact(locale: 'id_ID');

    return _SectionCard(
      title: 'Grafik Penjualan',
      subtitle: '14 hari terakhir',
      trailing: Icon(Icons.insights_rounded,
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
  const _LowStockCard({required this.items});
  final List<LowStockItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Stok Menipis',
      subtitle: items.isEmpty ? null : '${items.length} produk',
      trailing: const Icon(Icons.warning_amber_rounded,
          color: AppTheme.warning),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 36, color: AppTheme.success),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Semua stok aman 🎉',
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
                            ? Icons.remove_shopping_cart_rounded
                            : Icons.production_quantity_limits_rounded,
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
                    trailing: _StockPill(stock: it.stock, min: it.minStock),
                  ),
              ],
            ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock, required this.min});
  final double stock;
  final double min;

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
        out ? 'Habis' : '${stock.toInt()} / $min',
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
  const _ActivityCard({required this.entries});
  final List<ActivityEntry> entries;

  static final _df = DateFormat('d MMM · HH:mm');
  static final _money =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Aktivitas Terbaru',
      trailing: Icon(Icons.history_rounded,
          color: theme.colorScheme.primary),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text('Belum ada aktivitas.',
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
                            ? Icons.shopping_bag_rounded
                            : Icons.savings_rounded,
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
  const _GreetingChip({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 11
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 19
                ? 'Selamat sore'
                : 'Selamat malam';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('$greet · role $role',
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SyncBadge extends ConsumerWidget {
  const _SyncBadge({required this.status});
  final AsyncValue<SyncStatus> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = status.valueOrNull;
    final (icon, color) = switch (s?.phase) {
      SyncPhase.offline => (Icons.cloud_off_rounded, AppTheme.warning),
      SyncPhase.syncing => (Icons.sync_rounded, AppTheme.info),
      SyncPhase.error => (Icons.error_outline_rounded, AppTheme.error),
      _ => (Icons.cloud_done_rounded, AppTheme.success),
    };
    return Tooltip(
      message: switch (s?.phase) {
        SyncPhase.offline => 'Offline — data tetap aman di perangkat',
        SyncPhase.syncing => 'Sinkronisasi berjalan',
        SyncPhase.error => 'Sinkronisasi gagal',
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
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bug_report_outlined, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/design_tokens.dart';

/// Reusable loading skeleton untuk list/item cards.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
  });

  final int itemCount;
  final double itemHeight;
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _SkeletonItem(
          height: itemHeight,
          showAvatar: showAvatar,
          showSubtitle: showSubtitle,
          showTrailing: showTrailing,
          index: index,
          highlightColor: highlightColor,
        ),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({
    required this.height,
    required this.showAvatar,
    required this.showSubtitle,
    required this.showTrailing,
    required this.index,
    required this.highlightColor,
  });

  final double height;
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;
  final int index;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Animate(
      delay: (index * 100).ms,
      effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            if (showAvatar)
              const _SkeletonCircle(size: 44),
            if (showAvatar) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SkeletonLine(width: 0.6, height: 16),
                  if (showSubtitle) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const _SkeletonLine(width: 0.4, height: 12),
                  ],
                ],
              ),
            ),
            if (showTrailing)
              const _SkeletonLine(width: 60, height: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton untuk grid cards (dashboard stats, product grid, dll).
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.aspectRatio = 1.3,
    this.showHeader = true,
  });

  final int crossAxisCount;
  final int itemCount;
  final double aspectRatio;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, index) => Animate(
        delay: (index * 100).ms,
        effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
        child: _SkeletonGridCard(
          showHeader: showHeader,
          theme: theme,
        ),
      ),
    );
  }
}

class _SkeletonGridCard extends StatelessWidget {
  const _SkeletonGridCard({
    required this.showHeader,
    required this.theme,
  });

  final bool showHeader;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showHeader)
            const Row(
              children: [
                _SkeletonCircle(size: 36),
                Spacer(),
                _SkeletonLine(width: 40, height: 14),
              ],
            ),
          const _SkeletonLine(width: 0.8, height: 28),
          const SizedBox(height: AppSpacing.xs),
          const _SkeletonLine(width: 0.5, height: 14),
          if (showHeader) ...[
            const SizedBox(height: AppSpacing.sm),
            const _SkeletonLine(width: 0.7, height: 12),
          ],
        ],
      ),
    );
  }
}

/// Skeleton untuk chart area.
class SkeletonChart extends StatelessWidget {
  const SkeletonChart({super.key, this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return Animate(
      effects: [ShimmerEffect(duration: 1500.ms, color: highlightColor)],
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  _SkeletonLine(width: 0.5, height: 20),
                  Spacer(),
                  _SkeletonCircle(size: 20),
                ],
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: _SkeletonLine(width: double.infinity, height: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) => const _SkeletonLine(width: 30, height: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton untuk table rows.
class SkeletonTable extends StatelessWidget {
  const SkeletonTable({
    super.key,
    this.columnCount = 5,
    this.rowCount = 5,
    this.columnWidths,
  });

  final int columnCount;
  final int rowCount;
  final List<double>? columnWidths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return Column(
      children: [
        // Header skeleton
        Animate(
          effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: List.generate(columnCount, (i) => Expanded(
                flex: columnWidths != null && i < columnWidths!.length ? (columnWidths![i] * 10).round() : 1,
                child: const _SkeletonLine(width: 0.7, height: 14),
              )),
            ),
          ),
        ),
        // Body rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rowCount,
          itemBuilder: (_, rowIndex) => Animate(
            delay: (rowIndex * 100).ms,
            effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: List.generate(columnCount, (colIndex) => Expanded(
                  flex: columnWidths != null && colIndex < columnWidths!.length ? (columnWidths![colIndex] * 10).round() : 1,
                  child: const _SkeletonLine(width: 0.6, height: 14),
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Basic skeleton line.
class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width ?? double.infinity,
      height: height ?? 16,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// Basic skeleton circle.
class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Full page skeleton untuk halaman yang loading.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({
    super.key,
    this.hasAppBar = true,
    this.hasFAB = false,
    this.tabCount = 0,
  });

  final bool hasAppBar;
  final bool hasFAB;
  final int tabCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return Scaffold(
      appBar: hasAppBar ? AppBar(
        title: Animate(
          effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
          child: const _SkeletonLine(width: 120, height: 24),
        ),
        actions: [
          Animate(
            effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
            child: const _SkeletonCircle(size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Animate(
            effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
            child: const _SkeletonCircle(size: 24),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ) : null,
      body: Column(
        children: [
          if (tabCount > 0)
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: List.generate(tabCount, (i) => Animate(
                  delay: (i * 100).ms,
                  effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
                  child: const Expanded(child: _SkeletonLine(width: 0.6, height: 20)),
                )),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Stats cards row
                  Row(
                    children: [
                      Expanded(child: _StatSkeleton(highlightColor: highlightColor)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _StatSkeleton(highlightColor: highlightColor, delay: 100.ms)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _StatSkeleton(highlightColor: highlightColor, delay: 200.ms)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _StatSkeleton(highlightColor: highlightColor, delay: 300.ms)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Chart skeleton
                  const SkeletonChart(height: 240),
                  const SizedBox(height: AppSpacing.lg),
                  // List skeleton
                  const SkeletonList(itemCount: 4, itemHeight: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: hasFAB ? Animate(
        effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
        child: const _SkeletonCircle(size: 56),
      ) : null,
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton({required this.highlightColor, this.delay});

  final Color highlightColor;
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Animate(
      delay: delay ?? Duration.zero,
      effects: [ShimmerEffect(duration: 1200.ms, color: highlightColor)],
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonCircle(size: 36),
                Spacer(),
                _SkeletonLine(width: 50, height: 14),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            _SkeletonLine(width: 0.8, height: 28),
            SizedBox(height: AppSpacing.xs),
            _SkeletonLine(width: 0.5, height: 14),
          ],
        ),
      ),
    );
  }
}
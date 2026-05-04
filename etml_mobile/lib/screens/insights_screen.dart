import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/stats_provider.dart';
import '../services/api_service.dart';
import '../widgets/budget_goal_card.dart';
import '../widgets/insight_helpers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(expenseStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(expenseStatsProvider),
          color: EtmlColors.cyan,
          backgroundColor: EtmlColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            children: [
              Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Spending overview with category and trend signals.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              stats.when(
                data: (value) => value.isEmpty
                    ? const _InsightsEmpty()
                    : _InsightsContent(stats: value),
                loading: () => const _InsightsSkeleton(),
                error: (error, _) => _InsightsError(
                  message: '$error',
                  onRetry: () => ref.invalidate(expenseStatsProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.stats});

  final ExpenseStats stats;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroSpendCard(stats: stats),
          const SizedBox(height: 14),
          const BudgetGoalCard(),
          const SizedBox(height: 14),
          _StatGrid(stats: stats),
          const SizedBox(height: 18),
          _TrendCard(days: stats.last30Days),
          const SizedBox(height: 18),
          _CategoryBreakdown(items: stats.categoryBreakdown),
        ],
      ),
    );
  }
}

class _HeroSpendCard extends StatelessWidget {
  const _HeroSpendCard({required this.stats});

  final ExpenseStats stats;

  @override
  Widget build(BuildContext context) {
    final comparison = stats.monthComparisonPercentage;
    final isUp = comparison >= 0;
    final comparisonText =
        '${isUp ? '+' : ''}${comparison.toStringAsFixed(1)}% compared with last month';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EtmlColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33182762),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Monthly spending',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AnimatedMoney(
            value: stats.monthlyTotal,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Text(
              comparisonText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final ExpenseStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final width = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.category_rounded,
                label: 'Top category',
                value: stats.topCategory?.category ?? 'None',
                detail: stats.topCategory == null
                    ? 'No category spend yet'
                    : formatMoney(stats.topCategory!.total),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.today_rounded,
                label: 'Daily average',
                value: formatMoney(stats.dailyAverage),
                detail: 'Current month pace',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: EtmlColors.cyan.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: EtmlColors.cyan.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: EtmlColors.cyan, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: EtmlColors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: EtmlColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: EtmlColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.days});

  final List<DailySpend> days;

  @override
  Widget build(BuildContext context) {
    final activeDays = days.where((day) => day.total > 0).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Last 30 days',
            detail: '$activeDays active spending days',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 132,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: days.map((item) => item.total).toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.items});

  final List<CategorySpend> items;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.total > 0).toList();
    final maxTotal = visibleItems.fold<double>(
      0,
      (max, item) => math.max(max, item.total),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Category breakdown',
            detail: 'This month',
          ),
          const SizedBox(height: 16),
          if (visibleItems.isEmpty)
            Text(
              'No category totals yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: EtmlColors.muted),
            )
          else
            for (var index = 0; index < visibleItems.length; index++)
              _CategoryRow(
                item: visibleItems[index],
                progress: maxTotal == 0
                    ? 0
                    : visibleItems[index].total / maxTotal,
                index: index,
              ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.progress,
    required this.index,
  });

  final CategorySpend item;
  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: Duration(milliseconds: 420 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: EtmlColors.text),
                    ),
                  ),
                  Text(
                    formatMoney(item.total),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: EtmlColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: value,
                  color: EtmlColors.cyan,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: EtmlColors.cyan, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: EtmlColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          detail,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: EtmlColors.muted),
        ),
      ],
    );
  }
}

class _AnimatedMoney extends StatelessWidget {
  const _AnimatedMoney({required this.value, required this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (context, amount, _) {
        return Text(formatMoney(amount), style: style);
      },
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBox(height: 170, width: double.infinity),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: _SkeletonBox(height: 94)),
            SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 94)),
          ],
        ),
        const SizedBox(height: 18),
        const _SkeletonBox(height: 180, width: double.infinity),
        const SizedBox(height: 18),
        const _SkeletonBox(height: 220, width: double.infinity),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
    );
  }
}

class _InsightsEmpty extends StatelessWidget {
  const _InsightsEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: glassDecoration(),
      child: Column(
        children: [
          const Icon(Icons.insights_rounded, color: EtmlColors.cyan, size: 44),
          const SizedBox(height: 14),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to unlock spending insights.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EtmlColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EtmlColors.danger.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: EtmlColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: EtmlColors.danger),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EtmlColors.cyan.withValues(alpha: 0.18),
          EtmlColors.cyan.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    final linePaint = Paint()
      ..color = EtmlColors.cyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    if (values.length < 2 || values.every((value) => value == 0)) {
      final y = size.height * 0.68;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      return;
    }

    final maxValue = values.reduce(math.max);
    final path = Path();
    final fillPath = Path();

    for (var index = 0; index < values.length; index++) {
      final x = size.width * (index / (values.length - 1));
      final normalized = maxValue == 0 ? 0 : values[index] / maxValue;
      final y = size.height - (normalized * size.height * 0.82) - 10;

      if (index == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

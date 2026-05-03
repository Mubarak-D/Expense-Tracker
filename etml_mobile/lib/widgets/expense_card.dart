import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/api_service.dart';
import 'category_badge.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense, required this.index});

  final Expense expense;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: EtmlColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CategoryBadge(
                    category: expense.category,
                    confidence: expense.predictionConfidence,
                    compact: true,
                  ),
                  if (expense.corrected) ...[
                    const SizedBox(height: 8),
                    const _CorrectedChip(),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrectedChip extends StatelessWidget {
  const _CorrectedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: EtmlColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: EtmlColors.cyan.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Corrected',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: EtmlColors.cyan,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

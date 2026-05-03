import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/feedback_panel.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
          color: EtmlColors.cyan,
          backgroundColor: EtmlColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
            children: [
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Recent spending with model confidence attached to each category.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const FeedbackPanel(),
              const SizedBox(height: 18),
              transactions.when(
                data: (items) {
                  if (items.isEmpty) return const _EmptyLedger();
                  return Column(
                    children: [
                      _TotalStrip(
                        total: items.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < items.length; i++)
                        ExpenseCard(expense: items[i], index: i),
                    ],
                  );
                },
                loading: () => const _LedgerSkeleton(),
                error: (error, _) => _ErrorLedger(message: '$error'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalStrip extends StatelessWidget {
  const _TotalStrip({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: EtmlColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Visible spend',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerSkeleton extends StatelessWidget {
  const _LedgerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Container(
          height: 84,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.55 + (index % 2) * 0.18,
              child: Container(
                height: 12,
                margin: const EdgeInsets.only(left: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: EtmlColors.cyan,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first expense and it will appear here with its ML category.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorLedger extends StatelessWidget {
  const _ErrorLedger({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EtmlColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EtmlColors.danger.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: EtmlColors.danger),
      ),
    );
  }
}

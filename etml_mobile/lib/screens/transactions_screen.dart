import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/expense_provider.dart';
import '../services/api_service.dart';
import '../widgets/category_badge.dart';
import '../widgets/expense_card.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/recurring_expenses_panel.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const RecurringExpensesPanel(),
              const SizedBox(height: 18),
              _LedgerFilters(
                controller: _searchController,
                query: _query,
                category: _category,
                onQueryChanged: (value) => setState(() => _query = value),
                onCategoryChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 18),
              transactions.when(
                data: (items) {
                  final visibleItems = _filterExpenses(items);

                  if (items.isEmpty) return const _EmptyLedger();
                  if (visibleItems.isEmpty) return const _NoFilterMatches();

                  return Column(
                    children: [
                      _TotalStrip(
                        total: visibleItems.fold<double>(
                          0,
                          (sum, item) => sum + item.amount,
                        ),
                        count: visibleItems.length,
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < visibleItems.length; i++)
                        ExpenseCard(expense: visibleItems[i], index: i),
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

  List<Expense> _filterExpenses(List<Expense> items) {
    final normalizedQuery = _query.trim().toLowerCase();

    return items
        .where((expense) {
          final matchesCategory =
              _category == null || expense.category == _category;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              expense.description.toLowerCase().contains(normalizedQuery) ||
              expense.category.toLowerCase().contains(normalizedQuery) ||
              expense.predictedCategory.toLowerCase().contains(normalizedQuery);

          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }
}

class _LedgerFilters extends StatelessWidget {
  const _LedgerFilters({
    required this.controller,
    required this.query,
    required this.category,
    required this.onQueryChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController controller;
  final String query;
  final String? category;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search ledger',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AllCategoryChip(
                selected: category == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final item in ApiConstants.categories)
                CategoryBadge(
                  category: item,
                  compact: true,
                  selected: category == item,
                  onTap: () =>
                      onCategoryChanged(category == item ? null : item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllCategoryChip extends StatelessWidget {
  const _AllCategoryChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? EtmlColors.cyan.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? EtmlColors.cyan.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          'All',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? EtmlColors.cyan : EtmlColors.muted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TotalStrip extends StatelessWidget {
  const _TotalStrip({required this.total, required this.count});

  final double total;
  final int count;

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
              '$count visible ${count == 1 ? 'item' : 'items'}',
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

class _NoFilterMatches extends StatelessWidget {
  const _NoFilterMatches();

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
            Icons.filter_alt_off_rounded,
            color: EtmlColors.cyan,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text('No matches', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Try another search or category.',
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

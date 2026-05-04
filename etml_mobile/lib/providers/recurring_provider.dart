import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';
import 'goal_provider.dart';
import 'stats_provider.dart';

final recurringExpensesProvider =
    AsyncNotifierProvider<RecurringExpensesController, List<RecurringExpense>>(
      RecurringExpensesController.new,
    );

class RecurringExpensesController
    extends AsyncNotifier<List<RecurringExpense>> {
  @override
  Future<List<RecurringExpense>> build() {
    return ref.read(apiServiceProvider).getRecurringExpenses();
  }

  Future<void> create({
    required double amount,
    required String description,
    required String category,
    required DateTime nextRunDate,
  }) async {
    final recurringExpense = await ref
        .read(apiServiceProvider)
        .createRecurringExpense(
          amount: amount,
          description: description,
          category: category,
          nextRunDate: nextRunDate,
        );
    final current = state.value ?? const <RecurringExpense>[];
    state = AsyncData([recurringExpense, ...current]);
  }

  Future<void> postNow(String id) async {
    final result = await ref.read(apiServiceProvider).postRecurringExpense(id);
    final current = state.value ?? const <RecurringExpense>[];
    state = AsyncData([
      for (final item in current)
        if (item.id == id) result.recurringExpense else item,
    ]);

    final transactions =
        ref.read(transactionsProvider).value ?? const <Expense>[];
    ref.read(transactionsProvider.notifier).replace([
      result.expense,
      ...transactions,
    ]);
    ref.invalidate(expenseStatsProvider);
    ref.invalidate(budgetGoalProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(apiServiceProvider).deleteRecurringExpense(id);
    final current = state.value ?? const <RecurringExpense>[];
    state = AsyncData([
      for (final item in current)
        if (item.id != id) item,
    ]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).getRecurringExpenses(),
    );
  }
}

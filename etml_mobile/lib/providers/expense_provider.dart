import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'auth_provider.dart';

final transactionsProvider =
    AsyncNotifierProvider<TransactionsController, List<Expense>>(
      TransactionsController.new,
    );

final feedbackSummaryProvider = FutureProvider<FeedbackSummary>((ref) {
  return ref.read(apiServiceProvider).getFeedbackSummary();
});

class TransactionsController extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() {
    return ref.read(apiServiceProvider).getExpenses();
  }

  Future<Expense> addExpense({
    required double amount,
    required String description,
    String? category,
  }) async {
    final expense = await ref
        .read(apiServiceProvider)
        .createExpense(
          amount: amount,
          description: description,
          category: category,
    );
    final current = state.value ?? const <Expense>[];
    state = AsyncData([expense, ...current]);
    ref.invalidate(feedbackSummaryProvider);
    return expense;
  }

  void markCategoryOverride(String expenseId, String category) {
    final current = state.value ?? const <Expense>[];
    state = AsyncData([
      for (final expense in current)
        if (expense.id == expenseId)
          expense.copyWith(category: category, corrected: true)
        else
          expense,
    ]);
  }

  Future<Expense> updateCategory(String expenseId, String category) async {
    final updated = await ref
        .read(apiServiceProvider)
        .updateExpenseCategory(id: expenseId, category: category);
    final current = state.value ?? const <Expense>[];
    state = AsyncData([
      for (final expense in current)
        if (expense.id == expenseId) updated else expense,
    ]);
    ref.invalidate(feedbackSummaryProvider);
    return updated;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).getExpenses(),
    );
    ref.invalidate(feedbackSummaryProvider);
  }
}

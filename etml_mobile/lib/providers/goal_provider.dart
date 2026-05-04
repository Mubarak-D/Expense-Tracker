import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

final budgetGoalProvider =
    AsyncNotifierProvider<BudgetGoalController, BudgetGoalProgress>(
      BudgetGoalController.new,
    );

class BudgetGoalController extends AsyncNotifier<BudgetGoalProgress> {
  @override
  Future<BudgetGoalProgress> build() {
    ref.watch(transactionsProvider);
    return ref.read(apiServiceProvider).getCurrentGoal();
  }

  Future<void> saveGoal({String? month, required double monthlyLimit}) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(apiServiceProvider)
          .upsertGoal(month: month, monthlyLimit: monthlyLimit);
      final progress = await ref
          .read(apiServiceProvider)
          .getCurrentGoal(month: month);
      state = AsyncData(progress);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).getCurrentGoal(),
    );
  }
}

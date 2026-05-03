import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

final expenseStatsProvider = FutureProvider<ExpenseStats>((ref) {
  ref.watch(transactionsProvider);
  return ref.read(apiServiceProvider).getExpenseStats();
});

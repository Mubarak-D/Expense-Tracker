import 'package:etml_mobile/core/theme.dart';
import 'package:etml_mobile/providers/auth_provider.dart';
import 'package:etml_mobile/providers/expense_provider.dart';
import 'package:etml_mobile/providers/goal_provider.dart';
import 'package:etml_mobile/providers/recurring_provider.dart';
import 'package:etml_mobile/providers/stats_provider.dart';
import 'package:etml_mobile/screens/insights_screen.dart';
import 'package:etml_mobile/screens/login_screen.dart';
import 'package:etml_mobile/screens/transactions_screen.dart';
import 'package:etml_mobile/services/api_service.dart';
import 'package:etml_mobile/widgets/budget_goal_card.dart';
import 'package:etml_mobile/widgets/expense_card.dart';
import 'package:etml_mobile/widgets/recurring_expenses_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoggedOutAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState();
}

void main() {
  testWidgets('ETML app shows login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedOutAuthController.new),
        ],
        child: MaterialApp(theme: EtmlTheme.dark, home: const LoginScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ETML'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('corrected expenses show a subtle ledger indicator', (
    tester,
  ) async {
    final expense = Expense(
      id: 'expense-1',
      amount: 42,
      description: 'Ambiguous app purchase',
      category: 'Food',
      predictedCategory: 'Other',
      predictionConfidence: 0.42,
      corrected: true,
      date: DateTime.utc(2026, 5, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: EtmlTheme.dark,
        home: Scaffold(body: ExpenseCard(expense: expense, index: 0)),
      ),
    );

    expect(find.text('Corrected'), findsOneWidget);
    expect(find.text('Food (42%)'), findsOneWidget);
  });

  testWidgets('insights screen shows an empty state without expenses', (
    tester,
  ) async {
    const emptyStats = ExpenseStats(
      monthlyTotal: 0,
      categoryBreakdown: [],
      topCategory: null,
      dailyAverage: 0,
      last30Days: [],
      thisMonthTotal: 0,
      lastMonthTotal: 0,
      monthComparisonPercentage: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseStatsProvider.overrideWith((ref) async => emptyStats),
        ],
        child: MaterialApp(theme: EtmlTheme.dark, home: const InsightsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(
      find.text('Add your first expense to unlock spending insights.'),
      findsOneWidget,
    );
  });

  testWidgets('budget goal card shows empty state when no goal is set', (
    tester,
  ) async {
    const goal = BudgetGoalProgress(
      goalSet: false,
      month: '2026-04',
      message: 'No budget goal set for this month.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetGoalProvider.overrideWith(() => _BudgetGoalStub(goal)),
        ],
        child: MaterialApp(
          theme: EtmlTheme.dark,
          home: const Scaffold(body: BudgetGoalCard()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Budget Goal'), findsOneWidget);
    expect(find.text('Set Goal'), findsOneWidget);
    expect(
      find.text('Set a monthly goal to track your spending progress.'),
      findsOneWidget,
    );
  });

  testWidgets('budget goal card shows over-budget achievement state', (
    tester,
  ) async {
    const goal = BudgetGoalProgress(
      goalSet: true,
      month: '2026-04',
      monthlyLimit: 1000,
      totalSpent: 1200,
      remaining: -200,
      progressPercentage: 120,
      status: 'over_budget',
      achievement: BudgetAchievement(
        title: 'Reset Plan',
        description:
            'You have gone over your goal. Adjust spending or update your monthly target.',
        unlocked: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetGoalProvider.overrideWith(() => _BudgetGoalStub(goal)),
        ],
        child: MaterialApp(
          theme: EtmlTheme.dark,
          home: const Scaffold(body: BudgetGoalCard()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Over Budget'), findsOneWidget);
    expect(find.text('Reset Plan'), findsOneWidget);
    expect(find.text('-\$200'), findsOneWidget);
  });

  testWidgets('recurring panel shows saved templates', (tester) async {
    final recurring = [
      RecurringExpense(
        id: 'recurring-1',
        amount: 2500,
        description: 'Monthly rent',
        category: 'Bills',
        frequency: 'monthly',
        nextRunDate: DateTime.utc(2026, 5, 10),
        active: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringExpensesProvider.overrideWith(
            () => _RecurringExpenseStub(recurring),
          ),
        ],
        child: MaterialApp(
          theme: EtmlTheme.dark,
          home: const Scaffold(body: RecurringExpensesPanel()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('Monthly rent'), findsOneWidget);
    expect(find.text('\$2,500'), findsOneWidget);
    expect(find.text('Next 2026-05-10'), findsOneWidget);
  });

  testWidgets('transactions screen filters ledger by search text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final expenses = [
      Expense(
        id: 'expense-1',
        amount: 12,
        description: 'Coffee shop',
        category: 'Food',
        predictedCategory: 'Food',
        predictionConfidence: 0.92,
        corrected: false,
        date: DateTime.utc(2026, 5, 2),
      ),
      Expense(
        id: 'expense-2',
        amount: 80,
        description: 'Train pass',
        category: 'Transport',
        predictedCategory: 'Transport',
        predictionConfidence: 0.88,
        corrected: false,
        date: DateTime.utc(2026, 5, 3),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(() => _TransactionsStub(expenses)),
          recurringExpensesProvider.overrideWith(
            () => _RecurringExpenseStub(const []),
          ),
          feedbackSummaryProvider.overrideWith(
            (ref) async => const FeedbackSummary(
              totalCorrections: 0,
              lowConfidenceCorrections: 0,
              mostCorrectedPredictedCategory: null,
              correctionRate: 0,
            ),
          ),
        ],
        child: MaterialApp(
          theme: EtmlTheme.dark,
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Coffee shop'), findsOneWidget);
    expect(find.text('Train pass'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump();

    expect(find.text('Coffee shop'), findsOneWidget);
    expect(find.text('Train pass'), findsNothing);
    expect(find.text('1 visible item'), findsOneWidget);
  });
}

class _BudgetGoalStub extends BudgetGoalController {
  _BudgetGoalStub(this.goal);

  final BudgetGoalProgress goal;

  @override
  Future<BudgetGoalProgress> build() async => goal;
}

class _RecurringExpenseStub extends RecurringExpensesController {
  _RecurringExpenseStub(this.items);

  final List<RecurringExpense> items;

  @override
  Future<List<RecurringExpense>> build() async => items;
}

class _TransactionsStub extends TransactionsController {
  _TransactionsStub(this.items);

  final List<Expense> items;

  @override
  Future<List<Expense>> build() async => items;
}

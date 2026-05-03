import 'package:etml_mobile/core/theme.dart';
import 'package:etml_mobile/providers/auth_provider.dart';
import 'package:etml_mobile/providers/stats_provider.dart';
import 'package:etml_mobile/screens/insights_screen.dart';
import 'package:etml_mobile/screens/login_screen.dart';
import 'package:etml_mobile/services/api_service.dart';
import 'package:etml_mobile/widgets/expense_card.dart';
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
        child: MaterialApp(
          theme: EtmlTheme.dark,
          home: const InsightsScreen(),
        ),
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
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? 'ETML User'}',
      email: '${json['email'] ?? ''}',
    );
  }
}

class AuthResult {
  const AuthResult({required this.user, required this.token});
  final AppUser user;
  final String token;
}

class PredictionResult {
  const PredictionResult({
    required this.category,
    required this.confidence,
    required this.allProbabilities,
  });

  final String category;
  final double confidence;
  final Map<String, double> allProbabilities;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final raw = json['all_probabilities'];
    return PredictionResult(
      category: '${json['category'] ?? 'Other'}',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      allProbabilities: raw is Map
          ? raw.map((key, value) => MapEntry('$key', (value as num).toDouble()))
          : const {},
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.predictedCategory,
    required this.predictionConfidence,
    required this.corrected,
    required this.date,
  });

  final String id;
  final double amount;
  final String description;
  final String category;
  final String predictedCategory;
  final double predictionConfidence;
  final bool corrected;
  final DateTime date;

  Expense copyWith({String? category, bool? corrected}) {
    return Expense(
      id: id,
      amount: amount,
      description: description,
      category: category ?? this.category,
      predictedCategory: predictedCategory,
      predictionConfidence: predictionConfidence,
      corrected: corrected ?? this.corrected,
      date: date,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? 'Other'}',
      predictedCategory:
          '${json['predictedCategory'] ?? json['category'] ?? 'Other'}',
      predictionConfidence:
          (json['predictionConfidence'] as num?)?.toDouble() ?? 0,
      corrected: json['corrected'] == true,
      date:
          DateTime.tryParse('${json['date'] ?? json['createdAt'] ?? ''}') ??
          DateTime.now(),
    );
  }
}

class FeedbackExportItem {
  const FeedbackExportItem({
    required this.description,
    required this.predictedCategory,
    required this.correctedCategory,
    required this.confidence,
    required this.correctedAt,
  });

  final String description;
  final String predictedCategory;
  final String correctedCategory;
  final double confidence;
  final DateTime? correctedAt;

  factory FeedbackExportItem.fromJson(Map<String, dynamic> json) {
    return FeedbackExportItem(
      description: '${json['description'] ?? ''}',
      predictedCategory: '${json['predictedCategory'] ?? 'Other'}',
      correctedCategory: '${json['correctedCategory'] ?? 'Other'}',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      correctedAt: DateTime.tryParse('${json['correctedAt'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'predictedCategory': predictedCategory,
      'correctedCategory': correctedCategory,
      'confidence': confidence,
      'correctedAt': correctedAt?.toUtc().toIso8601String(),
    };
  }
}

class FeedbackExport {
  const FeedbackExport({required this.count, required this.data});

  final int count;
  final List<FeedbackExportItem> data;

  factory FeedbackExport.fromJson(Map<String, dynamic> json) {
    final items = json['data'];
    return FeedbackExport(
      count: (json['count'] as num?)?.toInt() ?? 0,
      data: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(FeedbackExportItem.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'data': data.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class FeedbackSummary {
  const FeedbackSummary({
    required this.totalCorrections,
    required this.lowConfidenceCorrections,
    required this.mostCorrectedPredictedCategory,
    required this.correctionRate,
  });

  final int totalCorrections;
  final int lowConfidenceCorrections;
  final String? mostCorrectedPredictedCategory;
  final double correctionRate;

  factory FeedbackSummary.fromJson(Map<String, dynamic> json) {
    final mostCorrected = json['mostCorrectedPredictedCategory'];
    return FeedbackSummary(
      totalCorrections: (json['totalCorrections'] as num?)?.toInt() ?? 0,
      lowConfidenceCorrections:
          (json['lowConfidenceCorrections'] as num?)?.toInt() ?? 0,
      mostCorrectedPredictedCategory: mostCorrected == null
          ? null
          : '$mostCorrected',
      correctionRate: (json['correctionRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CategorySpend {
  const CategorySpend({required this.category, required this.total});

  final String category;
  final double total;

  factory CategorySpend.fromJson(Map<String, dynamic> json) {
    return CategorySpend(
      category: '${json['category'] ?? 'Other'}',
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DailySpend {
  const DailySpend({required this.date, required this.total});

  final DateTime date;
  final double total;

  factory DailySpend.fromJson(Map<String, dynamic> json) {
    return DailySpend(
      date: DateTime.tryParse('${json['date'] ?? ''}') ?? DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExpenseStats {
  const ExpenseStats({
    required this.monthlyTotal,
    required this.categoryBreakdown,
    required this.topCategory,
    required this.dailyAverage,
    required this.last30Days,
    required this.thisMonthTotal,
    required this.lastMonthTotal,
    required this.monthComparisonPercentage,
  });

  final double monthlyTotal;
  final List<CategorySpend> categoryBreakdown;
  final CategorySpend? topCategory;
  final double dailyAverage;
  final List<DailySpend> last30Days;
  final double thisMonthTotal;
  final double lastMonthTotal;
  final double monthComparisonPercentage;

  bool get isEmpty =>
      monthlyTotal == 0 &&
      thisMonthTotal == 0 &&
      lastMonthTotal == 0 &&
      categoryBreakdown.every((item) => item.total == 0) &&
      last30Days.every((item) => item.total == 0);

  factory ExpenseStats.fromJson(Map<String, dynamic> json) {
    final categories = json['categoryBreakdown'];
    final days = json['last30Days'];
    final top = json['topCategory'];

    return ExpenseStats(
      monthlyTotal: (json['monthlyTotal'] as num?)?.toDouble() ?? 0,
      categoryBreakdown: categories is List
          ? categories
                .whereType<Map<String, dynamic>>()
                .map(CategorySpend.fromJson)
                .toList(growable: false)
          : const [],
      topCategory: top is Map<String, dynamic>
          ? CategorySpend.fromJson(top)
          : null,
      dailyAverage: (json['dailyAverage'] as num?)?.toDouble() ?? 0,
      last30Days: days is List
          ? days
                .whereType<Map<String, dynamic>>()
                .map(DailySpend.fromJson)
                .toList(growable: false)
          : const [],
      thisMonthTotal: (json['thisMonthTotal'] as num?)?.toDouble() ?? 0,
      lastMonthTotal: (json['lastMonthTotal'] as num?)?.toDouble() ?? 0,
      monthComparisonPercentage:
          (json['monthComparisonPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BudgetAchievement {
  const BudgetAchievement({
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String title;
  final String description;
  final bool unlocked;

  factory BudgetAchievement.fromJson(Map<String, dynamic> json) {
    return BudgetAchievement(
      title: '${json['title'] ?? 'Budget Guardian'}',
      description: '${json['description'] ?? ''}',
      unlocked: json['unlocked'] == true,
    );
  }
}

class BudgetGoalProgress {
  const BudgetGoalProgress({
    required this.goalSet,
    required this.month,
    this.monthlyLimit = 0,
    this.totalSpent = 0,
    this.remaining = 0,
    this.progressPercentage = 0,
    this.status,
    this.achievement,
    this.message,
  });

  final bool goalSet;
  final String month;
  final double monthlyLimit;
  final double totalSpent;
  final double remaining;
  final int progressPercentage;
  final String? status;
  final BudgetAchievement? achievement;
  final String? message;

  bool get isOnTrack => status == 'on_track';
  bool get isWarning => status == 'warning';
  bool get isOverBudget => status == 'over_budget';

  factory BudgetGoalProgress.fromJson(Map<String, dynamic> json) {
    final achievement = json['achievement'];

    return BudgetGoalProgress(
      goalSet: json['goalSet'] != false,
      month: '${json['month'] ?? ''}',
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.round() ?? 0,
      status: json['status'] == null ? null : '${json['status']}',
      achievement: achievement is Map<String, dynamic>
          ? BudgetAchievement.fromJson(achievement)
          : null,
      message: json['message'] == null ? null : '${json['message']}',
    );
  }
}

class BudgetGoal {
  const BudgetGoal({
    required this.id,
    required this.month,
    required this.monthlyLimit,
  });

  final String id;
  final String month;
  final double monthlyLimit;

  factory BudgetGoal.fromJson(Map<String, dynamic> json) {
    return BudgetGoal(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      month: '${json['month'] ?? ''}',
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.frequency,
    required this.nextRunDate,
    required this.active,
    this.lastPostedAt,
  });

  final String id;
  final double amount;
  final String description;
  final String category;
  final String frequency;
  final DateTime nextRunDate;
  final bool active;
  final DateTime? lastPostedAt;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? 'Other'}',
      frequency: '${json['frequency'] ?? 'monthly'}',
      nextRunDate:
          DateTime.tryParse('${json['nextRunDate'] ?? ''}') ?? DateTime.now(),
      active: json['active'] != false,
      lastPostedAt: DateTime.tryParse('${json['lastPostedAt'] ?? ''}'),
    );
  }
}

class RecurringPostResult {
  const RecurringPostResult({
    required this.expense,
    required this.recurringExpense,
  });

  final Expense expense;
  final RecurringExpense recurringExpense;

  factory RecurringPostResult.fromJson(Map<String, dynamic> json) {
    final expense = json['expense'];
    final recurringExpense = json['recurringExpense'];

    if (expense is! Map<String, dynamic> ||
        recurringExpense is! Map<String, dynamic>) {
      throw ApiException('Recurring expense post response was empty.');
    }

    return RecurringPostResult(
      expense: Expense.fromJson(expense),
      recurringExpense: RecurringExpense.fromJson(recurringExpense),
    );
  }
}

class ApiService {
  ApiService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _api = Dio(BaseOptions(baseUrl: ApiConstants.apiBaseUrl)),
      _ml = Dio() {
    _api.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static const _tokenKey = 'etml.jwt';

  final FlutterSecureStorage _storage;
  final Dio _api;
  final Dio _ml;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final body = response.data ?? {};
      final token = '${body['token'] ?? ''}';
      if (token.isEmpty || body['user'] is! Map<String, dynamic>) {
        throw ApiException('Login response was missing credentials.');
      }
      await saveToken(token);
      return AuthResult(
        user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
        token: token,
      );
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not sign in.'),
      );
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      final body = response.data ?? {};
      final token = '${body['token'] ?? ''}';
      if (token.isEmpty || body['user'] is! Map<String, dynamic>) {
        throw ApiException('Registration response was missing credentials.');
      }
      await saveToken(token);
      return AuthResult(
        user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
        token: token,
      );
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not create account.'),
      );
    }
  }

  Future<PredictionResult> predictCategory(String description) async {
    try {
      final response = await _ml.post<Map<String, dynamic>>(
        ApiConstants.mlPredictUrl,
        data: {'description': description.trim()},
      );
      return PredictionResult.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Prediction service is unavailable.'),
      );
    }
  }

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/api/expenses');
      final items = response.data?['expenses'];
      if (items is! List) return const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not load expenses.'),
      );
    }
  }

  Future<Expense> createExpense({
    required double amount,
    required String description,
    String? category,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/expenses',
        data: {
          'amount': amount,
          'description': description.trim(),
          if (category != null) 'category': category,
          'date': DateTime.now().toUtc().toIso8601String(),
        },
      );
      final expense = response.data?['expense'];
      if (expense is! Map<String, dynamic>) {
        throw ApiException('Expense response was empty.');
      }
      return Expense.fromJson(expense);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not save expense.'),
      );
    }
  }

  Future<Expense> updateExpenseCategory({
    required String id,
    required String category,
  }) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/api/expenses/$id',
        data: {'category': category},
      );
      final expense = response.data?['expense'];
      if (expense is! Map<String, dynamic>) {
        throw ApiException('Expense response was empty.');
      }
      return Expense.fromJson(expense);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not update category.'),
      );
    }
  }

  Future<FeedbackExport> exportFeedbackData() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/expenses/feedback/export',
      );
      return FeedbackExport.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not export feedback data.'),
      );
    }
  }

  Future<FeedbackSummary> getFeedbackSummary() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/expenses/feedback/summary',
      );
      return FeedbackSummary.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not load feedback summary.'),
      );
    }
  }

  Future<ExpenseStats> getExpenseStats() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/expenses/stats',
      );
      return ExpenseStats.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not load spending insights.'),
      );
    }
  }

  Future<BudgetGoalProgress> getCurrentGoal({String? month}) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/goals/current',
        queryParameters: {if (month != null) 'month': month},
      );
      return BudgetGoalProgress.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not load budget goal.'),
      );
    }
  }

  Future<BudgetGoal> upsertGoal({
    String? month,
    required double monthlyLimit,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/goals',
        data: {if (month != null) 'month': month, 'monthlyLimit': monthlyLimit},
      );
      final goal = response.data?['goal'];
      if (goal is! Map<String, dynamic>) {
        throw ApiException('Budget goal response was empty.');
      }
      return BudgetGoal.fromJson(goal);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not save budget goal.'),
      );
    }
  }

  Future<List<RecurringExpense>> getRecurringExpenses() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/recurring-expenses',
      );
      final items = response.data?['recurringExpenses'];
      if (items is! List) return const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpense.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not load recurring expenses.'),
      );
    }
  }

  Future<RecurringExpense> createRecurringExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime nextRunDate,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/recurring-expenses',
        data: {
          'amount': amount,
          'description': description.trim(),
          'category': category,
          'nextRunDate': nextRunDate.toUtc().toIso8601String(),
        },
      );
      final recurringExpense = response.data?['recurringExpense'];
      if (recurringExpense is! Map<String, dynamic>) {
        throw ApiException('Recurring expense response was empty.');
      }
      return RecurringExpense.fromJson(recurringExpense);
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not save recurring expense.'),
      );
    }
  }

  Future<RecurringPostResult> postRecurringExpense(String id) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/recurring-expenses/$id/post',
      );
      return RecurringPostResult.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not post recurring expense.'),
      );
    }
  }

  Future<void> deleteRecurringExpense(String id) async {
    try {
      await _api.delete<Map<String, dynamic>>('/api/recurring-expenses/$id');
    } on DioException catch (error) {
      throw ApiException(
        _messageFromDio(error, fallback: 'Could not delete recurring expense.'),
      );
    }
  }

  String _messageFromDio(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return '${data['message']}';
    if (data is Map && data['detail'] != null) return '${data['detail']}';
    if (error.type == DioExceptionType.connectionError) {
      return 'Connection failed. Check that the backend services are running.';
    }
    return fallback;
  }
}

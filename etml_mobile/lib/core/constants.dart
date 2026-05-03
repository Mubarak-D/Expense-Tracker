class ApiConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  static const mlPredictUrl = String.fromEnvironment(
    'ML_PREDICT_URL',
    defaultValue: 'http://localhost:8000/predict',
  );

  static const categories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Entertainment',
    'Education',
    'Other',
  ];
}

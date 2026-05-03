import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AuthState {
  const AuthState({
    this.user,
    this.token,
    this.isSubmitting = false,
    this.landingIndex = 0,
  });

  final AppUser? user;
  final String? token;
  final bool isSubmitting;
  final int landingIndex;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    AppUser? user,
    String? token,
    bool? isSubmitting,
    int? landingIndex,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      landingIndex: landingIndex ?? this.landingIndex,
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(apiServiceProvider).readToken();
    return AuthState(token: token);
  }

  Future<void> login(String email, String password) async {
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final result = await ref
          .read(apiServiceProvider)
          .login(email: email, password: password);
      state = AsyncData(AuthState(user: result.user, token: result.token));
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final result = await ref.read(apiServiceProvider).register(
            name: name,
            email: email,
            password: password,
          );
      state = AsyncData(
        AuthState(user: result.user, token: result.token, landingIndex: 1),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(apiServiceProvider).clearToken();
    state = const AsyncData(AuthState());
  }
}

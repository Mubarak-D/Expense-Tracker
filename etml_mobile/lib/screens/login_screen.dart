import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/animated_button.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isSubmitting = auth.value?.isSubmitting ?? false;

    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 28 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: EtmlColors.surface.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88020A1C),
                              blurRadius: 44,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: EtmlColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: const Icon(
                                  Icons.auto_graph_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'ETML',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Predictive expense tracking for sharper daily money decisions.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: EtmlColors.muted,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 28),
                              _FieldShell(
                                label: 'Email',
                                child: TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || !value.contains('@')) {
                                      return 'Enter a valid email.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FieldShell(
                                label: 'Password',
                                child: TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: const InputDecoration(
                                    hintText: 'Your password',
                                    prefixIcon: Icon(Icons.lock_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              AnimatedButton(
                                label: 'Sign in',
                                icon: Icons.arrow_forward_rounded,
                                loading: isSubmitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () {
                                          Navigator.of(context).push(
                                            PageRouteBuilder<void>(
                                              pageBuilder:
                                                  (_, animation, __) =>
                                                      FadeTransition(
                                                        opacity: animation,
                                                        child:
                                                            const RegisterScreen(),
                                                      ),
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 260,
                                                  ),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    'Create an account',
                                    style: Theme.of(context).textTheme.labelLarge
                                        ?.copyWith(color: EtmlColors.cyan),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Could not sign in. Please try again.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.8),
          radius: 1.2,
          colors: [Color(0xFF172C5C), EtmlColors.background],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EtmlColors.violet.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

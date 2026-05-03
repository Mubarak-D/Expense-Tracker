import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/animated_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isSubmitting = auth.value?.isSubmitting ?? false;

    return Scaffold(
      body: Stack(
        children: [
          const _RegisterBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
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
                          color: EtmlColors.surface.withValues(alpha: 0.70),
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
                              IconButton.filledTonal(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Create account',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start tracking expenses with model-assisted categories.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: EtmlColors.muted,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 26),
                              _FieldShell(
                                label: 'Name',
                                child: TextFormField(
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Your name',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length < 2) {
                                      return 'Enter your name.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
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
                              const SizedBox(height: 14),
                              _FieldShell(
                                label: 'Password',
                                child: TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Minimum 6 characters',
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
                              const SizedBox(height: 14),
                              _FieldShell(
                                label: 'Confirm password',
                                child: TextFormField(
                                  controller: _confirmPassword,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: const InputDecoration(
                                    hintText: 'Repeat password',
                                    prefixIcon: Icon(Icons.verified_rounded),
                                  ),
                                  validator: (value) {
                                    if (value != _password.text) {
                                      return 'Passwords do not match.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              AnimatedButton(
                                label: 'Register',
                                icon: Icons.person_add_alt_rounded,
                                loading: isSubmitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Back to sign in',
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
      await ref.read(authControllerProvider.notifier).register(
            _name.text,
            _email.text,
            _password.text,
          );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Could not create account. Please try again.');
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

class _RegisterBackdrop extends StatelessWidget {
  const _RegisterBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.75, -0.95),
          radius: 1.25,
          colors: [Color(0xFF1B2857), EtmlColors.background],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EtmlColors.cyan.withValues(alpha: 0.10),
          ),
        ),
      ),
    );
  }
}

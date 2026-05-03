import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../services/api_service.dart';
import '../widgets/animated_button.dart';
import '../widgets/category_badge.dart';
import '../widgets/premium_loader.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  Timer? _debounce;
  PredictionResult? _prediction;
  String? _selectedCategory;
  bool _categoryConfirmed = false;
  bool _predicting = false;
  bool _saving = false;
  String? _predictionError;

  @override
  void initState() {
    super.initState();
    _description.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _description.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    _debounce?.cancel();
    final text = _description.text.trim();
    if (text.length < 3) {
      setState(() {
        _prediction = null;
        _selectedCategory = null;
        _categoryConfirmed = false;
        _predictionError = null;
        _predicting = false;
      });
      return;
    }
    setState(() {
      _predicting = true;
      _categoryConfirmed = false;
      _predictionError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () => _predict(text));
  }

  Future<void> _predict(String description) async {
    try {
      final result = await ref
          .read(apiServiceProvider)
          .predictCategory(description);
      if (!mounted || description != _description.text.trim()) return;
      setState(() {
        _prediction = result;
        _selectedCategory = result.category;
        _predicting = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _predictionError = error.message;
        _predicting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _selectedCategory ?? _prediction?.category;
    final lowConfidence = _prediction != null && _prediction!.confidence < 0.60;

    return Scaffold(
      body: Stack(
        children: [
          const _ExpenseBackdrop(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 116),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add expense',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Type a description and ETML classifies it as you pause.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _GlassPanel(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            if (_description.text.trim().isNotEmpty) {
                              _save();
                              return;
                            }
                            _descriptionFocusNode.requestFocus();
                          },
                          decoration: const InputDecoration(
                            hintText: '42.50',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid amount.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _description,
                          focusNode: _descriptionFocusNode,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            hintText: 'Uber ride home',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Description is too short.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _predicting
                              ? const _PredictionLoading(
                                  key: ValueKey('loading'),
                                )
                              : _predictionError != null
                              ? _InlineNotice(
                                  key: const ValueKey('error'),
                                  text: _predictionError!,
                                  color: EtmlColors.warning,
                                )
                              : category != null
                              ? _PredictionDecision(
                                  key: ValueKey(
                                    '$category-${_prediction?.confidence}-$_categoryConfirmed',
                                  ),
                                  category: category,
                                  confidence: _prediction?.confidence,
                                  lowConfidence: lowConfidence,
                                  confirmed: _categoryConfirmed,
                                  onChange: _showCategoryPicker,
                                )
                              : const _InlineNotice(
                                  key: ValueKey('empty'),
                                  text: 'Prediction badge appears here.',
                                  color: EtmlColors.muted,
                                ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedButton(
                          label: 'Save expense',
                          icon: Icons.check_rounded,
                          loading: _saving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final selectedCategory = _selectedCategory ?? _prediction?.category;
      final expense = await ref
          .read(transactionsProvider.notifier)
          .addExpense(
            amount: double.parse(_amount.text),
            description: _description.text,
            category: selectedCategory,
          );
      if (selectedCategory != null && selectedCategory != expense.category) {
        await ref
            .read(transactionsProvider.notifier)
            .updateCategory(expense.id, selectedCategory);
      }
      _amount.clear();
      _description.clear();
      setState(() {
        _prediction = null;
        _selectedCategory = null;
        _categoryConfirmed = false;
      });
      _showSnack('Expense saved.');
    } on ApiException catch (error) {
      _showSnack(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EtmlColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose category',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'This will be saved as your confirmed category.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in ApiConstants.categories)
                      CategoryBadge(
                        category: category,
                        compact: true,
                        selected: category == _selectedCategory,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            _categoryConfirmed = true;
                          });
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EtmlColors.surface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PredictionDecision extends StatelessWidget {
  const _PredictionDecision({
    super.key,
    required this.category,
    required this.confidence,
    required this.lowConfidence,
    required this.confirmed,
    required this.onChange,
  });

  final String category;
  final double? confidence;
  final bool lowConfidence;
  final bool confirmed;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final accent = lowConfidence ? EtmlColors.warning : EtmlColors.cyan;
    final message = lowConfidence
        ? confirmed
              ? 'Category confirmed'
              : 'Low confidence - please confirm'
        : 'Tap to change category';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: lowConfidence ? 0.09 : 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryBadge(
            category: category,
            confidence: confidence,
            onTap: onChange,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                lowConfidence
                    ? Icons.warning_amber_rounded
                    : Icons.tune_rounded,
                color: accent,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onChange,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(confirmed ? 'Change' : 'Confirm'),
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictionLoading extends StatelessWidget {
  const _PredictionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Classifying', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            const PremiumLoader(size: 32, strokeWidth: 2.4),
            const SizedBox(width: 12),
            Text(
              'Reading signal',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: EtmlColors.cyan),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}

class _ExpenseBackdrop extends StatelessWidget {
  const _ExpenseBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101B35), EtmlColors.background],
        ),
      ),
    );
  }
}

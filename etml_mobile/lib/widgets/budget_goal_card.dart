import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/goal_provider.dart';
import '../services/api_service.dart';
import 'insight_helpers.dart';

class BudgetGoalCard extends ConsumerWidget {
  const BudgetGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(budgetGoalProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: goal.when(
        data: (value) => _BudgetGoalReady(
          key: ValueKey('goal-${value.goalSet}-${value.status}'),
          goal: value,
        ),
        loading: () => const _BudgetGoalLoading(key: ValueKey('goal-loading')),
        error: (error, _) => _BudgetGoalError(
          key: const ValueKey('goal-error'),
          message: '$error',
          onRetry: () => ref.read(budgetGoalProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _BudgetGoalReady extends StatelessWidget {
  const _BudgetGoalReady({super.key, required this.goal});

  final BudgetGoalProgress goal;

  @override
  Widget build(BuildContext context) {
    if (!goal.goalSet) {
      return _BudgetGoalEmpty(month: goal.month);
    }

    final status = _GoalStatus.from(goal);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GoalIcon(status: status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EtmlColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EtmlColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _GoalAmount(
                  label: 'Monthly limit',
                  value: formatMoney(goal.monthlyLimit),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalAmount(
                  label: 'Remaining',
                  value: formatMoney(goal.remaining),
                  color: status.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalProgressBar(goal: goal, status: status),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatMoney(goal.totalSpent)} spent',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: EtmlColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AchievementTile(goal: goal, status: status),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showGoalSheet(context, goal: goal),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Update Goal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EtmlColors.cyan,
                side: BorderSide(
                  color: EtmlColors.cyan.withValues(alpha: 0.35),
                ),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetGoalEmpty extends StatelessWidget {
  const _BudgetGoalEmpty({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: EtmlColors.cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: EtmlColors.cyan.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: EtmlColors.cyan,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EtmlColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set a monthly goal to track your spending progress.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EtmlColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Set a monthly goal to unlock spending progress and lightweight achievements.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: EtmlColors.muted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showGoalSheet(context, month: month),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Set Goal'),
              style: FilledButton.styleFrom(
                backgroundColor: EtmlColors.cyan.withValues(alpha: 0.13),
                foregroundColor: EtmlColors.cyan,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  const _GoalProgressBar({required this.goal, required this.status});

  final BudgetGoalProgress goal;
  final _GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final target = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: value,
            color: status.color,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.goal, required this.status});

  final BudgetGoalProgress goal;
  final _GoalStatus status;

  @override
  Widget build(BuildContext context) {
    final achievement = goal.achievement;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(status.achievementIcon, color: status.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement?.title ?? status.achievementTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: EtmlColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement?.description ?? status.achievementDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EtmlColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalAmount extends StatelessWidget {
  const _GoalAmount({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: EtmlColors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GoalIcon extends StatelessWidget {
  const _GoalIcon({required this.status});

  final _GoalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Icon(status.icon, color: status.color, size: 21),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _GoalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: status.color.withValues(alpha: 0.24)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BudgetGoalLoading extends StatelessWidget {
  const _BudgetGoalLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(widthFactor: 0.44, height: 14),
          const SizedBox(height: 18),
          _SkeletonLine(widthFactor: 0.72),
          const SizedBox(height: 12),
          _SkeletonLine(widthFactor: 0.58),
          const Spacer(),
          _SkeletonLine(widthFactor: 1, height: 12),
          const SizedBox(height: 16),
          _SkeletonLine(widthFactor: 0.64),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.height = 10});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _BudgetGoalError extends StatelessWidget {
  const _BudgetGoalError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EtmlColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EtmlColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: EtmlColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: EtmlColors.warning),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _GoalStatus {
  const _GoalStatus({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
    required this.achievementIcon,
    required this.achievementTitle,
    required this.achievementDescription,
  });

  final String label;
  final String message;
  final Color color;
  final IconData icon;
  final IconData achievementIcon;
  final String achievementTitle;
  final String achievementDescription;

  static _GoalStatus from(BudgetGoalProgress goal) {
    if (goal.isOverBudget) {
      return const _GoalStatus(
        label: 'Over Budget',
        message:
            'You have gone over your goal. Adjust spending or update your goal.',
        color: EtmlColors.danger,
        icon: Icons.priority_high_rounded,
        achievementIcon: Icons.restart_alt_rounded,
        achievementTitle: 'Reset Plan',
        achievementDescription:
            'Review spending and choose the next best adjustment.',
      );
    }

    if (goal.isWarning) {
      return const _GoalStatus(
        label: 'Close to Limit',
        message: 'Close to your monthly limit.',
        color: EtmlColors.warning,
        icon: Icons.timelapse_rounded,
        achievementIcon: Icons.savings_rounded,
        achievementTitle: 'Careful Spender',
        achievementDescription:
            'You are close to your goal and still have room to adjust.',
      );
    }

    return const _GoalStatus(
      label: 'On Track',
      message: 'You are on track this month.',
      color: EtmlColors.cyan,
      icon: Icons.verified_rounded,
      achievementIcon: Icons.shield_rounded,
      achievementTitle: 'Budget Guardian',
      achievementDescription:
          'You are staying within your monthly spending goal.',
    );
  }
}

Future<void> showGoalSheet(
  BuildContext context, {
  BudgetGoalProgress? goal,
  String? month,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _GoalSheet(goal: goal, month: month),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({this.goal, this.month});

  final BudgetGoalProgress? goal;
  final String? month;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limit = TextEditingController(
    text: widget.goal?.monthlyLimit == null || widget.goal!.monthlyLimit == 0
        ? ''
        : widget.goal!.monthlyLimit.round().toString(),
  );
  bool _saving = false;

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(budgetGoalProvider.notifier)
          .saveGoal(
            month: widget.goal?.month ?? widget.month,
            monthlyLimit: double.parse(_limit.text),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget goal saved.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: EtmlColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.goal?.goalSet == true
                            ? 'Update goal'
                            : 'Set goal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a monthly limit to track progress without changing your expense history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  'Monthly limit',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _limit,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    hintText: '50000',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a monthly limit greater than 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

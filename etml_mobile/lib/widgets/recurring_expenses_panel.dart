import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/recurring_provider.dart';
import '../services/api_service.dart';
import 'category_badge.dart';
import 'insight_helpers.dart';

class RecurringExpensesPanel extends ConsumerWidget {
  const RecurringExpensesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringExpensesProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: EtmlColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recurring',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EtmlColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => showRecurringExpenseSheet(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add recurring expense',
              ),
            ],
          ),
          const SizedBox(height: 14),
          recurring.when(
            data: (items) => items.isEmpty
                ? const _RecurringEmpty()
                : Column(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        _RecurringExpenseRow(
                          item: items[index],
                          isLast: index == items.length - 1,
                        ),
                    ],
                  ),
            loading: () => const _RecurringLoading(),
            error: (error, _) => _RecurringError(message: '$error'),
          ),
        ],
      ),
    );
  }
}

class _RecurringExpenseRow extends ConsumerWidget {
  const _RecurringExpenseRow({required this.item, required this.isLast});

  final RecurringExpense item;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: EtmlColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(item.amount),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CategoryBadge(category: item.category, compact: true),
                    _TinyChip(
                      icon: Icons.calendar_month_rounded,
                      label: 'Next ${_formatDate(item.nextRunDate)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Recurring actions',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (value == 'post') {
                  await ref
                      .read(recurringExpensesProvider.notifier)
                      .postNow(item.id);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Recurring expense posted.')),
                  );
                }
                if (value == 'delete') {
                  await ref
                      .read(recurringExpensesProvider.notifier)
                      .delete(item.id);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Recurring expense removed.')),
                  );
                }
              } on ApiException catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'post', child: Text('Post now')),
              PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: EtmlColors.muted, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: EtmlColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringEmpty extends StatelessWidget {
  const _RecurringEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Track rent, subscriptions, and other repeat spending here.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: EtmlColors.muted, height: 1.35),
    );
  }
}

class _RecurringLoading extends StatelessWidget {
  const _RecurringLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonLine(widthFactor: 0.86),
        const SizedBox(height: 10),
        _SkeletonLine(widthFactor: 0.62),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _RecurringError extends StatelessWidget {
  const _RecurringError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: EtmlColors.warning),
    );
  }
}

Future<void> showRecurringExpenseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _RecurringExpenseSheet(),
  );
}

class _RecurringExpenseSheet extends ConsumerStatefulWidget {
  const _RecurringExpenseSheet();

  @override
  ConsumerState<_RecurringExpenseSheet> createState() =>
      _RecurringExpenseSheetState();
}

class _RecurringExpenseSheetState
    extends ConsumerState<_RecurringExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Bills';
  DateTime _nextRunDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(recurringExpensesProvider.notifier)
          .create(
            amount: double.parse(_amount.text),
            description: _description.text,
            category: _category,
            nextRunDate: _nextRunDate,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recurring expense saved.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRunDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: EtmlColors.cyan,
              surface: EtmlColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _nextRunDate = picked);
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
                        'Add recurring expense',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    hintText: '2500',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter an amount greater than 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    hintText: 'Monthly rent',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Description is too short.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in ApiConstants.categories)
                      CategoryBadge(
                        category: category,
                        compact: true,
                        selected: category == _category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text('Next run ${_formatDate(_nextRunDate)}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

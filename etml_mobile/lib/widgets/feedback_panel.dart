import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../services/api_service.dart';

class FeedbackPanel extends ConsumerStatefulWidget {
  const FeedbackPanel({super.key});

  @override
  ConsumerState<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends ConsumerState<FeedbackPanel> {
  bool _exporting = false;

  Future<void> _exportFeedback() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final export = await ref.read(apiServiceProvider).exportFeedbackData();
      if (export.count == 0) {
        _showSnack('No manual corrections to export yet.');
        return;
      }

      const encoder = JsonEncoder.withIndent('  ');
      await Clipboard.setData(ClipboardData(text: encoder.convert(export)));
      _showSnack('Feedback JSON copied for future retraining.');
    } on ApiException catch (error) {
      _showSnack(error.message);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(feedbackSummaryProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
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
      child: summary.when(
        data: (value) => _FeedbackCard(
          key: const ValueKey('feedback-ready'),
          summary: value,
          exporting: _exporting,
          onExport: _exportFeedback,
        ),
        loading: () => const _FeedbackLoading(key: ValueKey('feedback-loading')),
        error: (error, _) => _FeedbackError(
          key: const ValueKey('feedback-error'),
          message: '$error',
          onRetry: () => ref.invalidate(feedbackSummaryProvider),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    super.key,
    required this.summary,
    required this.exporting,
    required this.onExport,
  });

  final FeedbackSummary summary;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final rate = (summary.correctionRate * 100).round();
    final hasCorrections = summary.totalCorrections > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.052),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: EtmlColors.cyan.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: EtmlColors.cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: EtmlColors.cyan.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.model_training_rounded,
                  color: EtmlColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ML Feedback',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EtmlColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCorrections
                          ? 'Feedback saved for future model improvement.'
                          : 'Manual corrections will appear here.',
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
          if (hasCorrections)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FeedbackMetric(
                  label: 'Corrections saved',
                  value: '${summary.totalCorrections}',
                ),
                _FeedbackMetric(
                  label: 'Low-confidence fixes',
                  value: '${summary.lowConfidenceCorrections}',
                ),
                _FeedbackMetric(label: 'Correction rate', value: '$rate%'),
              ],
            )
          else
            Text(
              'Confirm or change a predicted category to create export-ready training feedback.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: EtmlColors.muted),
            ),
          if (summary.mostCorrectedPredictedCategory != null) ...[
            const SizedBox(height: 12),
            Text(
              'Most corrected prediction: ${summary.mostCorrectedPredictedCategory}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: EtmlColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: exporting ? null : onExport,
              icon: exporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 18),
              label: Text(
                exporting ? 'Preparing export' : 'Export Feedback Data',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: EtmlColors.cyan.withValues(alpha: 0.13),
                foregroundColor: EtmlColors.cyan,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                disabledForegroundColor: EtmlColors.muted,
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

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: EtmlColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FeedbackLoading extends StatelessWidget {
  const _FeedbackLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 132,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          for (final width in const [0.78, 0.52, 0.66])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedbackError extends StatelessWidget {
  const _FeedbackError({
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

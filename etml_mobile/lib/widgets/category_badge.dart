import 'package:flutter/material.dart';

import '../core/theme.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.confidence,
    this.onTap,
    this.compact = false,
    this.selected = false,
  });

  final String category;
  final double? confidence;
  final VoidCallback? onTap;
  final bool compact;
  final bool selected;

  bool get _lowConfidence => confidence != null && confidence! < 0.60;

  @override
  Widget build(BuildContext context) {
    final color = _lowConfidence ? EtmlColors.warning : _colorFor(category);
    final percent = confidence == null ? null : (confidence! * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.72 : 0.34),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(category), size: compact ? 15 : 17, color: color),
              SizedBox(width: compact ? 6 : 8),
              Text(
                percent == null ? category : '$category ($percent%)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(String value) {
    return switch (value) {
      'Food' => const Color(0xFF74D99F),
      'Transport' => EtmlColors.blue,
      'Bills' => const Color(0xFFFFD166),
      'Shopping' => EtmlColors.violet,
      'Health' => const Color(0xFFFF8BA7),
      'Entertainment' => const Color(0xFF64D2FF),
      'Education' => EtmlColors.cyan,
      _ => const Color(0xFFC5CBD8),
    };
  }

  IconData _iconFor(String value) {
    return switch (value) {
      'Food' => Icons.restaurant_rounded,
      'Transport' => Icons.directions_car_rounded,
      'Bills' => Icons.bolt_rounded,
      'Shopping' => Icons.shopping_bag_rounded,
      'Health' => Icons.favorite_rounded,
      'Entertainment' => Icons.movie_rounded,
      'Education' => Icons.school_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

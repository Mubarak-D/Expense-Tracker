import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'premium_loader.dart';

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final Future<void> Function()? onPressed;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active =
        widget.enabled && !widget.loading && widget.onPressed != null;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: active
          ? (_) async {
              setState(() => _pressed = false);
              await widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: active || widget.loading ? 1 : 0.52,
          duration: const Duration(milliseconds: 180),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: EtmlColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3375A7FF),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: widget.loading
                    ? const PremiumLoader(
                        key: ValueKey('loader'),
                        size: 30,
                        strokeWidth: 2.6,
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 21),
                            const SizedBox(width: 9),
                          ],
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

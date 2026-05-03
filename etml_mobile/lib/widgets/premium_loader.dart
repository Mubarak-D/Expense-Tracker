import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class PremiumLoader extends StatefulWidget {
  const PremiumLoader({
    super.key,
    this.size = 34,
    this.strokeWidth = 3,
    this.showOrbit = true,
  });

  final double size;
  final double strokeWidth;
  final bool showOrbit;

  @override
  State<PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = 0.72 + math.sin(_controller.value * math.pi * 2) * 0.16;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * pulse,
                height: widget.size * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EtmlColors.cyan.withValues(alpha: 0.34),
                      EtmlColors.violet.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _GradientRingPainter(
                    strokeWidth: widget.strokeWidth,
                    showOrbit: widget.showOrbit,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final phase = (_controller.value + index * 0.18) % 1;
                  final dotScale = 0.72 + math.sin(phase * math.pi * 2) * 0.22;
                  return Transform.scale(
                    scale: dotScale,
                    child: Container(
                      width: widget.size * 0.12,
                      height: widget.size * 0.12,
                      margin: EdgeInsets.symmetric(
                        horizontal: widget.size * 0.035,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.62 + phase * 0.30,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({
    required this.strokeWidth,
    required this.showOrbit,
  });

  final double strokeWidth;
  final bool showOrbit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          EtmlColors.cyan,
          EtmlColors.blue,
          EtmlColors.violet,
          Colors.transparent,
        ],
        stops: [0.0, 0.28, 0.55, 0.78, 1.0],
      ).createShader(rect);

    if (showOrbit) {
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.10);
      canvas.drawCircle(size.center(Offset.zero), size.width / 2.7, orbitPaint);
    }

    canvas.drawArc(
      rect.deflate(strokeWidth),
      -math.pi / 2,
      math.pi * 1.55,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showOrbit != showOrbit;
  }
}

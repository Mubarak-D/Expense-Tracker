import 'package:flutter/material.dart';

BoxDecoration glassDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.052),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

String formatMoney(double value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final raw = rounded.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index++) {
    final positionFromEnd = raw.length - index;
    buffer.write(raw[index]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${negative ? '-' : ''}\$${buffer.toString()}';
}

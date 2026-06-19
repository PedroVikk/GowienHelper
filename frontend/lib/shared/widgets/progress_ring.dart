import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Anel de progresso (substitui o `conic-gradient` do protótipo), com glow neon.
class ProgressRing extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  final Color color;
  final double stroke;
  final Widget? center;
  final bool glow;

  const ProgressRing({
    super.key,
    required this.size,
    required this.progress,
    required this.color,
    this.stroke = 8,
    this.center,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress, color, stroke, glow),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  final bool glow;

  _RingPainter(this.progress, this.color, this.stroke, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..color = Gw.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    const start = -math.pi / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    if (glow && progress > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(arcRect, start, sweep, false, glowPaint);
    }

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}

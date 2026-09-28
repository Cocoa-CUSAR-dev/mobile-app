import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

/// Loading indicator: a cacao bean wobbling above a cup, shedding little
/// grounds that fall in and fill it -- a "grinding and brewing" loop
/// instead of a generic spinner. Same size/color API as the old
/// three-dots version, so every existing `ThreeDotsLoading()` call site
/// picked this up with no other changes.
class ThreeDotsLoading extends StatefulWidget {
  final Color color;
  final double size;

  const ThreeDotsLoading({
    super.key,
    this.color = AppColors.primary,
    this.size = 10.0,
  });

  @override
  State<ThreeDotsLoading> createState() => _ThreeDotsLoadingState();
}

class _ThreeDotsLoadingState extends State<ThreeDotsLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size / 10.0;
    return SizedBox(
      width: 64 * scale,
      height: 64 * scale,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: BrewingBeanPainter(color: widget.color, t: _controller.value),
          );
        },
      ),
    );
  }
}

/// Paints the whole "grind and brew" scene for one animation cycle,
/// `t` in [0, 1). Public so widget tests can construct/inspect it.
class BrewingBeanPainter extends CustomPainter {
  final Color color;
  final double t;

  const BrewingBeanPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cup sits in the lower half; the bean grinds above it.
    final cupTop = h * 0.55;
    final cupWidth = w * 0.62;
    final cupHeight = h * 0.4;
    final cupLeft = (w - cupWidth) / 2;
    final cupRect = Rect.fromLTWH(cupLeft, cupTop, cupWidth, cupHeight);

    _paintGrounds(canvas, w, h, cupTop);
    _paintCup(canvas, cupRect);
    _paintBean(canvas, w, h);
  }

  void _paintBean(Canvas canvas, double w, double h) {
    // Wobbles side to side and pulses slightly, like it's being pressed
    // against a grinder -- doesn't travel, so it reads as the source the
    // grounds keep falling from.
    final wobble = math.sin(t * 2 * math.pi * 3) * 0.15;
    final cx = w * 0.5;
    final cy = h * 0.22;
    final beanW = w * 0.22;
    final beanH = h * 0.3;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(wobble);
    final rect = Rect.fromCenter(center: Offset.zero, width: beanW, height: beanH);
    _drawBeanShape(canvas, rect, color);
    canvas.restore();
  }

  void _drawBeanShape(Canvas canvas, Rect rect, Color color) {
    final w = rect.width;
    final h = rect.height;
    final left = rect.left;
    final top = rect.top;
    final outline = Path()
      ..moveTo(left + w * 0.5, top)
      ..cubicTo(left + w * 0.95, top + h * 0.12, left + w * 0.95, top + h * 0.4, left + w * 0.7, top + h * 0.5)
      ..cubicTo(left + w * 0.95, top + h * 0.6, left + w * 0.95, top + h * 0.88, left + w * 0.5, top + h)
      ..cubicTo(left + w * 0.05, top + h * 0.88, left + w * 0.05, top + h * 0.6, left + w * 0.3, top + h * 0.5)
      ..cubicTo(left + w * 0.05, top + h * 0.4, left + w * 0.05, top + h * 0.12, left + w * 0.5, top)
      ..close();
    canvas.drawPath(outline, Paint()..color = color);

    final seam = Path()
      ..moveTo(left + w * 0.5, top + h * 0.08)
      ..quadraticBezierTo(left + w * 0.32, top + h * 0.5, left + w * 0.5, top + h * 0.92);
    canvas.drawPath(
      seam,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintGrounds(Canvas canvas, double w, double h, double cupTop) {
    // Three grains, staggered through the cycle, each falling from the
    // bean down into the cup and fading out once "in" the liquid.
    const count = 3;
    for (var i = 0; i < count; i++) {
      final phase = (t + i / count) % 1.0;
      if (phase > 0.7) continue; // resting between falls
      final fall = phase / 0.7; // 0..1 over the fall
      final startY = h * 0.28;
      final endY = cupTop + 4;
      final y = startY + (endY - startY) * fall;
      final drift = math.sin(i * 2.1) * w * 0.05;
      final x = w * 0.5 + drift * fall;
      final opacity = fall < 0.85 ? 1.0 : (1 - fall) / 0.15;

      canvas.drawCircle(
        Offset(x, y),
        w * 0.025,
        Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }
  }

  void _paintCup(Canvas canvas, Rect cupRect) {
    final w = cupRect.width;
    final h = cupRect.height;
    final left = cupRect.left;
    final top = cupRect.top;

    // Cup body: narrower at the base, like a small espresso cup.
    final body = Path()
      ..moveTo(left, top)
      ..lineTo(left + w, top)
      ..lineTo(left + w * 0.85, top + h)
      ..lineTo(left + w * 0.15, top + h)
      ..close();

    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // Liquid fill level rises and gently sloshes as grounds land.
    final fillLevel = 0.25 + 0.55 * ((math.sin(t * 2 * math.pi) + 1) / 2) * 0.3 + 0.35;
    final liquidTop = top + h * (1 - fillLevel.clamp(0.35, 0.92));
    final liquidPath = Path()
      ..moveTo(left + w * 0.06, liquidTop)
      ..lineTo(left + w * 0.94, liquidTop)
      ..lineTo(left + w * 0.85, top + h - 2)
      ..lineTo(left + w * 0.15, top + h - 2)
      ..close();
    canvas.drawPath(liquidPath, Paint()..color = color.withValues(alpha: 0.85));

    // Handle.
    final handleCenter = Offset(left + w + w * 0.12, top + h * 0.45);
    canvas.drawArc(
      Rect.fromCenter(center: handleCenter, width: w * 0.32, height: h * 0.55),
      -math.pi * 0.65,
      math.pi * 1.3,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // Saucer.
    canvas.drawLine(
      Offset(left - w * 0.12, top + h + 2),
      Offset(left + w * 1.12, top + h + 2),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant BrewingBeanPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

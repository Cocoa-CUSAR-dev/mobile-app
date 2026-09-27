import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';

/// Three tumbling cacao-bean shapes, used everywhere the app shows a
/// loading state. Same size/color API as the old plain-dot version, so
/// every existing `ThreeDotsLoading()` call site picked this up for free.
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
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Same stagger as before (0.2 cycle offset per bean), but the
            // bean shape needs both a bounce and a tumble/rotation to read
            // as "rolling" rather than just a bouncing dot with corners.
            final delay = index * 0.2;
            final t = (_controller.value + delay) % 1.0;
            final bounce = Curves.easeInOut.transform(
              t < 0.5 ? t * 2 : (1 - t) * 2,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Transform.rotate(
                  angle: t * 2 * 3.14159,
                  child: Container(
                    width: widget.size,
                    height: widget.size * 1.35,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.size),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

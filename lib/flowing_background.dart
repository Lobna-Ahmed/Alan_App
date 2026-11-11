import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft S-shaped bands of color that slowly curve and shift.
/// Wrap any screen's content with it. Light and dark mode are automatic.
class FlowingBackground extends StatefulWidget {
  final Widget child;
  const FlowingBackground({super.key, required this.child});

  @override
  State<FlowingBackground> createState() => _FlowingBackgroundState();
}

class _FlowingBackgroundState extends State<FlowingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _flow,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _FlowPainter(_flow.value, c),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Band {
  final double center; // where the S sits, 0 = left edge, 1 = right edge
  final double thickness; // as a fraction of the screen width
  final double offset; // starting point of the wave
  final double speed; // 1 or -1: which way the wave moves
  const _Band(this.center, this.thickness, this.offset, this.speed);
}

class _FlowPainter extends CustomPainter {
  final double t; // 0 to 1, loops
  final AppColors colors;
  _FlowPainter(this.t, this.colors);

  static const _bands = [
    _Band(0.30, 0.70, 0.0, 1),
    _Band(0.68, 0.65, 2.1, -1),
    _Band(0.50, 0.50, 4.2, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Plain background color
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.base);

    for (var i = 0; i < _bands.length; i++) {
      final b = _bands[i];
      final phase = 2 * math.pi * t * b.speed + b.offset;

      // The S shape: x moves left and right as y goes down.
      final path = Path();
      var first = true;
      for (double y = -40; y <= h + 40; y += 10) {
        final x = w * b.center +
            w * 0.30 * math.sin((y / h) * 2 * math.pi + phase);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * b.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors.bands[i].withAlpha(180)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.22);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.t != t || old.colors != colors;
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedCheckCircle extends StatefulWidget {
  final bool isDone;
  final VoidCallback onTap;
  final double size;
  const AnimatedCheckCircle({Key? key, required this.isDone, required this.onTap, this.size = 44}) : super(key: key);
  @override
  State<AnimatedCheckCircle> createState() => _AnimatedCheckCircleState();
}

class _AnimatedCheckCircleState extends State<AnimatedCheckCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    if (widget.isDone) _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCheckCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone) {
      _ctrl.forward();
    } else if (!widget.isDone && oldWidget.isDone) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDone ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CircleProgressPainter(
                progress: _progressAnim.value,
                isDone: widget.isDone,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final bool isDone;
  _CircleProgressPainter({required this.progress, required this.isDone});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bgPaint = Paint()
      ..color = isDone ? AppColors.success.withOpacity(0.15) : AppColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14 / 2,
        progress * 2 * 3.14,
        false,
        arcPaint,
      );
    }

    if (isDone && progress > 0.7) {
      final checkPaint = Paint()
        ..color = AppColors.success
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final opacity = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      checkPaint.color = AppColors.success.withOpacity(opacity);
      final p1 = Offset(center.dx - radius * 0.35, center.dy);
      final p2 = Offset(center.dx - radius * 0.1, center.dy + radius * 0.3);
      final p3 = Offset(center.dx + radius * 0.4, center.dy - radius * 0.3);
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy);
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress || old.isDone != isDone;
}

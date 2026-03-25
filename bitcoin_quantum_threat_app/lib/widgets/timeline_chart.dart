import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';

/// Horizontal timeline with staggered markers (like Streamlit Plotly layout).
class TimelineChart extends StatelessWidget {
  const TimelineChart({super.key, required this.events});

  final List<TimelineEvent> events;

  static const _minY = 2017.0;
  static const _maxY = 2045.0;

  Color _color(String type) {
    switch (type) {
      case 'quantum':
        return AppColors.quantum;
      case 'crypto':
        return AppColors.accent;
      case 'bitcoin':
        return AppColors.migration;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 120.0;
        return SizedBox(
          height: h + 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: h,
                width: w,
                child: CustomPaint(
                  painter: _TimelinePainter(
                    events: events,
                    minY: _minY,
                    maxY: _maxY,
                    colorFor: _color,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('2017', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  Text('2045', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.events,
    required this.minY,
    required this.maxY,
    required this.colorFor,
  });

  final List<TimelineEvent> events;
  final double minY;
  final double maxY;
  final Color Function(String type) colorFor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisY = size.height * 0.55;
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), linePaint);

    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final t = (e.year - minY) / (maxY - minY);
      final x = t.clamp(0.02, 0.98) * size.width;
      final yOff = ((i % 3) - 1) * 18.0;
      final y = axisY + yOff;
      final c = colorFor(e.type);
      final r = 7.0;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = c
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${e.year}',
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      tp.paint(canvas, Offset(x - tp.width / 2, y - r - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) => oldDelegate.events != events;
}

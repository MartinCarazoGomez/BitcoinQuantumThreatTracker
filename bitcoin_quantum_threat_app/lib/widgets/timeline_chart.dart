import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';

/// One horizontal baseline; events alternate above / below so labels stay visible.
class TimelineChart extends StatelessWidget {
  const TimelineChart({super.key, required this.events});

  final List<TimelineEvent> events;

  static const double _minYear = 2016;
  static const double _maxYear = 2040;
  static const double _lineY = 132;
  static const double _stackHeight = 268;
  static const double _labelW = 138;
  static const double _padH = 10;

  static Color _colorFor(String type) {
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

  static double _yearToX(int year, double trackW) {
    final t = (year - _minYear) / (_maxYear - _minYear);
    return t.clamp(0.0, 1.0) * trackW;
  }

  /// Slight horizontal shift when several milestones share a year (keeps dots apart).
  static double _sameYearNudge(List<TimelineEvent> sorted, int i) {
    final y = sorted[i].year;
    var start = i;
    while (start > 0 && sorted[start - 1].year == y) {
      start--;
    }
    final indexInRun = i - start;
    return (indexInRun * 12.0).clamp(0.0, 36.0);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<TimelineEvent>.from(events)
      ..sort((a, b) {
        final y = a.year.compareTo(b.year);
        if (y != 0) return y;
        return a.title.compareTo(b.title);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _LegendDot(color: AppColors.quantum, label: 'Quantum'),
            _LegendDot(color: AppColors.accent, label: 'Crypto'),
            _LegendDot(color: AppColors.migration, label: 'Bitcoin'),
            _LegendDot(color: AppColors.amber, label: 'Model'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Single line · alternate above / below · ${_minYear.toInt()}–${_maxYear.toInt()}',
          style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.88)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: sorted.isEmpty
              ? Text(
                  'No events.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9)),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final trackW = (c.maxWidth - _padH * 2).clamp(120.0, double.infinity);
                    return SizedBox(
                      height: _stackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: _padH,
                            right: _padH,
                            top: _lineY,
                            height: 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.muted.withValues(alpha: 0.15),
                                    AppColors.amber.withValues(alpha: 0.45),
                                    AppColors.muted.withValues(alpha: 0.15),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          for (var i = 0; i < sorted.length; i++)
                            _EventAlongLine(
                              event: sorted[i],
                              color: _colorFor(sorted[i].type),
                              cx: _padH +
                                  _yearToX(sorted[i].year, trackW) +
                                  _sameYearNudge(sorted, i),
                              trackWidth: c.maxWidth,
                              above: i.isEven,
                            ),
                          Positioned(
                            left: _padH,
                            right: _padH,
                            bottom: 0,
                            height: 22,
                            child: _YearTicks(trackW: trackW),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _YearTicks extends StatelessWidget {
  const _YearTicks({required this.trackW});

  final double trackW;

  static const _ticks = [2016, 2024, 2032, 2040];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final y in _ticks)
          Positioned(
            left: TimelineChart._yearToX(y, trackW) - 16,
            width: 32,
            child: Text(
              '$y',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted.withValues(alpha: 0.85),
              ),
            ),
          ),
      ],
    );
  }
}

class _EventAlongLine extends StatelessWidget {
  const _EventAlongLine({
    required this.event,
    required this.color,
    required this.cx,
    required this.trackWidth,
    required this.above,
  });

  final TimelineEvent event;
  final Color color;
  final double cx;
  final double trackWidth;
  final bool above;

  static const double _dot = 13.0;

  @override
  Widget build(BuildContext context) {
    final left = (cx - TimelineChart._labelW / 2).clamp(
      TimelineChart._padH,
      trackWidth - TimelineChart._labelW - TimelineChart._padH,
    );

    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${event.year}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          event.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            height: 1.25,
            fontWeight: FontWeight.w500,
            color: AppColors.text.withValues(alpha: 0.9),
          ),
        ),
      ],
    );

    final dot = Container(
      width: _dot,
      height: _dot,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 1)),
        ],
      ),
    );

    if (above) {
      return Positioned(
        left: left,
        top: 0,
        width: TimelineChart._labelW,
        height: TimelineChart._lineY - 4,
        child: Column(
          children: [
            Expanded(child: Center(child: label)),
            dot,
          ],
        ),
      );
    }

    return Positioned(
      left: left,
      top: TimelineChart._lineY + 4,
      width: TimelineChart._labelW,
      height: TimelineChart._stackHeight - TimelineChart._lineY - 28,
      child: Column(
        children: [
          dot,
          const SizedBox(height: 4),
          Expanded(child: Center(child: label)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 3)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

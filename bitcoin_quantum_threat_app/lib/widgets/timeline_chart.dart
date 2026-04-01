import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';

/// Left column width for lane labels — must match the year axis row spacer.
const double _kTimelineLaneLabelWidth = 108;

/// Horizontal timeline: swimlanes by category so years and titles stay readable.
class TimelineChart extends StatelessWidget {
  const TimelineChart({super.key, required this.events});

  final List<TimelineEvent> events;

  static const double _minYear = 2016;
  static const double _maxYear = 2040;

  static const _axisTicks = [2016, 2020, 2024, 2028, 2032, 2036, 2040];

  static int _laneIndex(String type) {
    switch (type) {
      case 'quantum':
        return 0;
      case 'crypto':
        return 1;
      case 'bitcoin':
        return 2;
      case 'model':
        return 3;
      default:
        return 0;
    }
  }

  static const _laneLabels = ['Quantum hardware', 'Crypto / standards', 'Bitcoin', 'Model / policy'];

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

  double _yearToX(int year, double trackWidth) {
    final t = (year - _minYear) / (_maxYear - _minYear);
    return t.clamp(0.0, 1.0) * trackWidth;
  }

  @override
  Widget build(BuildContext context) {
    final byLane = List<List<TimelineEvent>>.generate(4, (_) => []);
    for (final e in events) {
      byLane[_laneIndex(e.type)].add(e);
    }
    for (final list in byLane) {
      list.sort((a, b) => a.year.compareTo(b.year));
    }

    const laneAccent = [AppColors.quantum, AppColors.accent, AppColors.migration, AppColors.amber];

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
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var lane = 0; lane < 4; lane++) ...[
                if (lane > 0) const SizedBox(height: 8),
                _Swimlane(
                  label: _laneLabels[lane],
                  labelColor: laneAccent[lane],
                  events: byLane[lane],
                  colorFor: _color,
                  yearToX: _yearToX,
                  axisTicks: _axisTicks,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: _kTimelineLaneLabelWidth),
                  Expanded(
                    child: _YearAxis(
                      minYear: _minYear,
                      maxYear: _maxYear,
                      ticks: _axisTicks,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Swimlane extends StatelessWidget {
  const _Swimlane({
    required this.label,
    required this.labelColor,
    required this.events,
    required this.colorFor,
    required this.yearToX,
    required this.axisTicks,
  });

  final String label;
  final Color labelColor;
  final List<TimelineEvent> events;
  final Color Function(String type) colorFor;
  final double Function(int year, double trackWidth) yearToX;
  final List<int> axisTicks;

  static const double _laneHeight = 88;
  static const double _labelWidth = _kTimelineLaneLabelWidth;

  /// Horizontal gap (px) below which same-lane markers are nudged apart.
  static const double _minMarkerGap = 72;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: labelColor.withValues(alpha: 0.98),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final trackW = c.maxWidth;
              final nudge = _stackNudges(events, trackW);
              return SizedBox(
                height: _laneHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _laneHeight * 0.58,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.02),
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final y in axisTicks)
                      Positioned(
                        left: yearToX(y, trackW),
                        top: 2,
                        bottom: 10,
                        child: Container(
                          width: 1,
                          color: AppColors.muted.withValues(alpha: 0.12),
                        ),
                      ),
                    for (var i = 0; i < events.length; i++)
                      _EventMarker(
                        event: events[i],
                        trackWidth: trackW,
                        color: colorFor(events[i].type),
                        yearToX: yearToX,
                        stackNudgeY: nudge[i],
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

  /// Slight vertical offsets when two events in the same lane map to nearby x positions.
  List<double> _stackNudges(List<TimelineEvent> sorted, double trackW) {
    if (sorted.isEmpty) return [];
    final out = List<double>.filled(sorted.length, 0);
    var lastX = -1e9;
    var stack = 0;
    for (var i = 0; i < sorted.length; i++) {
      final cx = yearToX(sorted[i].year, trackW);
      if (i > 0 && (cx - lastX).abs() < _minMarkerGap) {
        stack++;
        out[i] = (stack.isOdd ? 1 : -1) * (10.0 + (stack - 1) * 4);
      } else {
        stack = 0;
        out[i] = 0;
      }
      lastX = cx;
    }
    return out;
  }
}

class _EventMarker extends StatelessWidget {
  const _EventMarker({
    required this.event,
    required this.trackWidth,
    required this.color,
    required this.yearToX,
    required this.stackNudgeY,
  });

  final TimelineEvent event;
  final double trackWidth;
  final Color color;
  final double Function(int year, double trackWidth) yearToX;
  final double stackNudgeY;

  @override
  Widget build(BuildContext context) {
    final cx = yearToX(event.year, trackWidth);
    const markerW = 104.0;
    final left = (cx - markerW / 2).clamp(0.0, trackWidth - markerW);

    return Positioned(
      left: left,
      top: stackNudgeY,
      width: markerW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${event.year}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearAxis extends StatelessWidget {
  const _YearAxis({
    required this.minYear,
    required this.maxYear,
    required this.ticks,
  });

  final double minYear;
  final double maxYear;
  final List<int> ticks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Year',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.muted.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Container(height: 1, color: AppColors.amber.withValues(alpha: 0.28)),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final y in ticks)
                    Positioned(
                      left: ((y - minYear) / (maxYear - minYear)) * w - 20,
                      width: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 1,
                            height: 5,
                            color: AppColors.muted.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$y',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

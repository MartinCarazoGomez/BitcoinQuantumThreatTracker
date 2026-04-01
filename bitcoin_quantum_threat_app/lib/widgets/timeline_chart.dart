import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';

/// One horizontal baseline; events alternate above / below so labels stay visible.
class TimelineChart extends StatelessWidget {
  const TimelineChart({super.key, required this.events});

  final List<TimelineEvent> events;

  static const double _minYear = 2016;
  static const double _maxYear = 2040;
  /// Vertical space reserved under the plot for year labels (keep in sync with [_EventAlongLine]).
  static const double _tickBand = 24;
  /// Baseline position — chosen so above / below regions are similar height for readability.
  static const double _lineY = 149;
  static const double _stackHeight = 321;
  /// Narrow phones: taller plot + lower baseline so alternating bands fit.
  static const double _narrowBreakpoint = 420;
  static const double _lineYNarrow = 159;
  static const double _stackHeightNarrow = 351;
  static const double _labelW = 52;
  static const double _padH = 8;

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
    return (indexInRun * 9.0).clamp(0.0, 27.0);
  }

  /// NIST PQC + IBM Osprey (both 2022): hug the baseline (handled in [_EventAlongLine]).
  static bool _compactLine(TimelineEvent e) {
    if (e.year != 2022) return false;
    if (e.title.contains('NIST PQC')) return true;
    if (e.title.contains('Osprey')) return true;
    return false;
  }

  /// Fine-tune vertical position for specific milestones (label only; dot unchanged).
  static double _extraLabelDy(TimelineEvent e) {
    if (e.year == 2023 && e.type == 'quantum') return -6;
    return 0;
  }

  /// NIST PQC sits just above the line; IBM Osprey just below (same year, fixed sides).
  static List<bool> _aboveFlags(List<TimelineEvent> sorted) {
    return List<bool>.generate(sorted.length, (i) {
      final e = sorted[i];
      if (e.year == 2022 && e.title.contains('NIST PQC')) return true;
      if (e.year == 2022 && e.title.contains('Osprey')) return false;
      return i.isEven;
    });
  }

  /// When label centers are close on the same side of the line, stagger text vertically.
  static List<double> _labelVerticalNudges(
    List<TimelineEvent> sorted,
    List<double> cx,
    List<bool> above,
    double layoutWidth,
  ) {
    final n = sorted.length;
    final nudge = List<double>.filled(n, 0);

    final isNarrow = layoutWidth < _narrowBreakpoint;
    /// ~label width 138 — stagger when centers are close enough that text can collide.
    final proximity = isNarrow ? 84.0 : 76.0;
    /// Keep narrow layouts visually consistent (avoid very high/low outliers).
    final step = isNarrow ? 9.0 : 14.0;
    final maxLayers = isNarrow ? 2 : 5;

    for (final side in [true, false]) {
      final idx = <int>[];
      for (var i = 0; i < n; i++) {
        if (above[i] == side && !_compactLine(sorted[i])) idx.add(i);
      }
      idx.sort((a, b) => cx[a].compareTo(cx[b]));
      final depth = List<int>.filled(idx.length, 0);
      for (var t = 0; t < idx.length; t++) {
        final i = idx[t];
        var d = 0;
        for (var u = 0; u < t; u++) {
          final j = idx[u];
          if ((cx[i] - cx[j]).abs() < proximity) {
            d = math.max(d, depth[u] + 1);
          }
        }
        depth[t] = math.min(d, maxLayers);
        nudge[i] = side ? (-depth[t] * step) : (depth[t] * step);
      }
    }

    /// Always offset from the line by x-order on each side.
    /// Pattern: near, near, far, far...
    final band = isNarrow ? 8.0 : 6.0;
    for (final side in [true, false]) {
      final idx = <int>[];
      for (var i = 0; i < n; i++) {
        if (above[i] == side && !_compactLine(sorted[i])) idx.add(i);
      }
      idx.sort((a, b) => cx[a].compareTo(cx[b]));
      for (var t = 0; t < idx.length; t++) {
        final i = idx[t];
        final far = (t % 4) >= 2;
        if (!far) continue; // "near" keeps computed nudge
        if (side) {
          nudge[i] -= band; // above: farther = more negative (higher)
        } else {
          nudge[i] += band; // below: farther = more positive (lower)
        }
      }
    }

    // Hard cap keeps labels in consistent vertical bands.
    final cap = isNarrow ? 20.0 : 24.0;
    for (var i = 0; i < n; i++) {
      if (_compactLine(sorted[i])) continue;
      if (above[i]) {
        nudge[i] = nudge[i].clamp(-cap, 0.0);
      } else {
        nudge[i] = nudge[i].clamp(0.0, cap);
      }
    }

    return nudge;
  }

  /// Enforces a minimum horizontal gap between points on the same side.
  static List<double> _enforceMinDistanceBySide(
    List<double> centers,
    List<bool> above,
    double left,
    double right,
    double minGap,
  ) {
    final out = List<double>.from(centers);
    final available = (right - left).clamp(0.0, double.infinity);
    if (available <= 0) return out;

    for (final side in [true, false]) {
      final idx = <int>[];
      for (var i = 0; i < out.length; i++) {
        if (above[i] == side) idx.add(i);
      }
      if (idx.length < 2) continue;
      idx.sort((a, b) => out[a].compareTo(out[b]));

      final maxGap = available / (idx.length - 1);
      final gap = math.min(minGap, maxGap);

      for (var t = 1; t < idx.length; t++) {
        final prev = idx[t - 1];
        final cur = idx[t];
        final minX = out[prev] + gap;
        if (out[cur] < minX) out[cur] = minX;
      }

      final overflow = out[idx.last] - right;
      if (overflow > 0) {
        for (final i in idx) {
          out[i] -= overflow;
        }
      }
      final underflow = left - out[idx.first];
      if (underflow > 0) {
        for (final i in idx) {
          out[i] += underflow;
        }
      }
    }
    return out;
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
          spacing: 8,
          runSpacing: 5,
          children: [
            _LegendDot(color: AppColors.quantum, label: 'Quantum'),
            _LegendDot(color: AppColors.accent, label: 'Crypto'),
            _LegendDot(color: AppColors.migration, label: 'Bitcoin'),
            _LegendDot(color: AppColors.amber, label: 'Model'),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < _narrowBreakpoint;
            return Text(
              narrow
                  ? 'Narrow layout: labels zig-zag higher/lower on each side · ${_minYear.toInt()}–${_maxYear.toInt()}'
                  : 'Single line · alternate above / below · ${_minYear.toInt()}–${_maxYear.toInt()}',
              style: TextStyle(fontSize: 8, color: AppColors.muted.withValues(alpha: 0.88)),
            );
          },
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(9, 11, 9, 9),
          child: sorted.isEmpty
              ? Text(
                  'No events.',
                  style: TextStyle(fontSize: 8, color: AppColors.muted.withValues(alpha: 0.9)),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final trackW = (c.maxWidth - _padH * 2).clamp(120.0, double.infinity);
                    final narrow = c.maxWidth < _narrowBreakpoint;
                    final chartH = narrow ? _stackHeightNarrow : _stackHeight;
                    final lineY = narrow ? _lineYNarrow : _lineY;
                    final aboveList = _aboveFlags(sorted);
                    final rawCx = List<double>.generate(
                      sorted.length,
                      (i) => _padH + _yearToX(sorted[i].year, trackW) + _sameYearNudge(sorted, i),
                    );
                    final pointCx = _enforceMinDistanceBySide(
                      rawCx,
                      aboveList,
                      _padH,
                      c.maxWidth - _padH,
                      narrow ? 17.0 : 21.0,
                    );
                    final nudges = _labelVerticalNudges(sorted, pointCx, aboveList, c.maxWidth);
                    return SizedBox(
                      height: chartH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: _padH,
                            right: _padH,
                            top: lineY,
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
                              cx: pointCx[i],
                              trackWidth: c.maxWidth,
                              lineY: lineY,
                              chartHeight: chartH,
                              above: aboveList[i],
                              labelNudgeY: nudges[i],
                              compactToLine: _compactLine(sorted[i]),
                            ),
                          Positioned(
                            left: _padH,
                            right: _padH,
                            bottom: 0,
                            height: _tickBand,
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
            left: TimelineChart._yearToX(y, trackW) - 12,
            width: 24,
            child: Text(
              '$y',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
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
    required this.lineY,
    required this.chartHeight,
    required this.above,
    required this.labelNudgeY,
    required this.compactToLine,
  });

  final TimelineEvent event;
  final Color color;
  final double cx;
  final double trackWidth;
  final double lineY;
  final double chartHeight;
  final bool above;
  /// Extra vertical offset for label text (dots stay on the baseline).
  final double labelNudgeY;
  /// Label + dot hug the baseline (2022 NIST above, 2022 Osprey below).
  final bool compactToLine;

  static const double _dot = 10.0;

  @override
  Widget build(BuildContext context) {
    final left = (cx - TimelineChart._labelW / 2).clamp(
      TimelineChart._padH,
      trackWidth - TimelineChart._labelW - TimelineChart._padH,
    );

    final label = Transform.translate(
      offset: Offset(0, labelNudgeY + TimelineChart._extraLabelDy(event)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${event.year}',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7,
              height: 1.28,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
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
      if (compactToLine) {
        return Positioned(
          left: left,
          top: 0,
          width: TimelineChart._labelW,
          height: lineY - 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              label,
              const SizedBox(height: 3),
              dot,
            ],
          ),
        );
      }
      return Positioned(
        left: left,
        top: 0,
        width: TimelineChart._labelW,
        height: lineY - 4,
        child: Column(
          children: [
            Expanded(child: Center(child: label)),
            dot,
          ],
        ),
      );
    }

    if (compactToLine) {
      return Positioned(
        left: left,
        top: lineY + 2,
        width: TimelineChart._labelW,
        height: chartHeight - lineY - TimelineChart._tickBand,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dot,
            const SizedBox(height: 3),
            label,
          ],
        ),
      );
    }

    return Positioned(
      left: left,
      top: lineY + 4,
      width: TimelineChart._labelW,
      height: chartHeight - lineY - TimelineChart._tickBand,
      child: Column(
        children: [
          dot,
          const SizedBox(height: 7),
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 2)],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.muted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

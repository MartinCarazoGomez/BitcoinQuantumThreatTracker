import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';

/// Vertical chronological timeline: one rail, events in year order (not swimlanes).
class TimelineChart extends StatelessWidget {
  const TimelineChart({super.key, required this.events});

  final List<TimelineEvent> events;

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

  static String _typeLabel(String type) {
    switch (type) {
      case 'quantum':
        return 'Quantum';
      case 'crypto':
        return 'Crypto';
      case 'bitcoin':
        return 'Bitcoin';
      case 'model':
        return 'Model';
      default:
        return type;
    }
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
        const SizedBox(height: 6),
        Text(
          'Chronological · ${sorted.isEmpty ? '—' : '${sorted.first.year}–${sorted.last.year}'}',
          style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.88)),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: sorted.isEmpty
              ? Text(
                  'No events.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9)),
                )
              : Column(
                  children: [
                    for (var i = 0; i < sorted.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == sorted.length - 1 ? 0 : 12),
                        child: _TimelineEntry(
                          event: sorted[i],
                          accent: _colorFor(sorted[i].type),
                          typeLabel: _typeLabel(sorted[i].type),
                        ),
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

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.accent,
    required this.typeLabel,
  });

  final TimelineEvent event;
  final Color accent;
  final String typeLabel;

  static const _railW = 44.0;
  static const _node = 16.0;
  static const _dotTop = 18.0;

  @override
  Widget build(BuildContext context) {
    final line = AppColors.muted.withValues(alpha: 0.32);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 21,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: line),
                ),
                Positioned(
                  left: 13,
                  top: _dotTop,
                  child: Container(
                    width: _node,
                    height: _node,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2.5),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _EventCard(
              year: event.year,
              title: event.title,
              detail: event.detail,
              accent: accent,
              typeLabel: typeLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.year,
    required this.title,
    required this.detail,
    required this.accent,
    required this.typeLabel,
  });

  final int year;
  final String title;
  final String detail;
  final Color accent;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.85), width: 3),
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent.withValues(alpha: 0.95)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.muted.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

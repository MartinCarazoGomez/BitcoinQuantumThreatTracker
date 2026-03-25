import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TimelineEvent {
  TimelineEvent(this.year, this.title, this.type, this.detail);
  final int year;
  final String title;
  final String type;
  final String detail;
}

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  static final _events = <TimelineEvent>[
    TimelineEvent(2019, 'Google quantum supremacy (Sycamore)', 'quantum', '~53-qubit processor; Nature, 23 Oct 2019'),
    TimelineEvent(2021, 'IBM Eagle processor', 'quantum', '127-qubit chip publicly announced'),
    TimelineEvent(2021, 'Bitcoin Taproot activation', 'bitcoin', 'Soft fork at block 709,632 (Nov 2021)'),
    TimelineEvent(2022, 'NIST PQC algorithm selection', 'crypto', 'Kyber, Dilithium, SPHINCS+ chosen (July 2022)'),
    TimelineEvent(2022, 'IBM Osprey processor', 'quantum', '433-qubit processor announced (Nov 2022)'),
    TimelineEvent(2023, 'IBM Condor / System Two', 'quantum', '1121-qubit processor announced (Dec 2023)'),
    TimelineEvent(2024, 'NIST FIPS post-quantum standards', 'crypto', 'FIPS 203, 204, 205; Aug 2024'),
    TimelineEvent(2026, 'This simulator horizon start', 'model', 'App default window— not a forecast'),
  ];

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
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Documented announcements and standards dates. The last row is for this app only.',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.4),
          ),
          const SizedBox(height: 16),
          ..._events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _color(e.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.year} · ${e.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(e.detail, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
                        Text(
                          e.type,
                          style: TextStyle(fontSize: 10, color: _color(e.type), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

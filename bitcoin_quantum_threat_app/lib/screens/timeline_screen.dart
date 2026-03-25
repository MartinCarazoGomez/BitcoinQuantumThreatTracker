import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_theme.dart';
import '../widgets/timeline_chart.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  Color _chipColor(String type) {
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
            'Historical rows follow documented announcements and standards dates. '
            'The last row is only for this simulator—not a real-world prediction.',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quantum & Bitcoin PQC Timeline',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TimelineChart(events: kTimelineEvents),
          const SizedBox(height: 8),
          const Text(
            'Type: quantum = hardware; crypto = NIST; bitcoin = consensus; model = in-app only.',
            style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surface.withValues(alpha: 0.5)),
              columns: const [
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Event')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Detail')),
              ],
              rows: [
                for (final e in kTimelineEvents)
                  DataRow(
                    cells: [
                      DataCell(Text('${e.year}')),
                      DataCell(SizedBox(width: 200, child: Text(e.title, style: const TextStyle(fontSize: 12)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _chipColor(e.type).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(e.type, style: TextStyle(fontSize: 11, color: _chipColor(e.type))),
                        ),
                      ),
                      DataCell(SizedBox(width: 260, child: Text(e.detail, style: const TextStyle(fontSize: 11)))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

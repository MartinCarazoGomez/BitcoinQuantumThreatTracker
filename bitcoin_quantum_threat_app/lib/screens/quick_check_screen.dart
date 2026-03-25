import 'package:flutter/material.dart';

import '../engine/risk_engine.dart';
import '../theme/app_theme.dart';

class QuickCheckScreen extends StatefulWidget {
  const QuickCheckScreen({super.key});

  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  int _q1 = 0;
  int _q2 = 0;
  int _q3 = 0;
  int _q4 = 0;
  bool _submitted = false;

  static const _o1 = [
    '2040 or later (optimistic)',
    '2035–2040 (moderate)',
    'Before 2035 (pessimistic)',
  ];
  static const _o2 = [
    'By 2032 (early)',
    '2032–2040 (moderate)',
    'After 2040 or unclear (late)',
  ];
  static const _o3 = ['Under 60%', '60–80%', 'Over 80%'];
  static const _o4 = [
    'Strong — clear roadmap',
    'Moderate — some uncertainty',
    'Weak — fragmented',
  ];

  int _score() {
    int s = 0;
    s += _q1 == 0 ? 0 : (_q1 == 1 ? 1 : 2);
    s += _q2 == 0 ? 0 : (_q2 == 1 ? 1 : 2);
    s += _q3 == 0 ? 0 : (_q3 == 1 ? 1 : 2);
    s += _q4 == 0 ? 0 : (_q4 == 1 ? 1 : 2);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Risk Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Answer four questions for an instant risk snapshot.',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 16),
          _radioBlock('When do you expect quantum to reach ~50% capability (break ECDSA)?', _o1, _q1, (v) => setState(() => _q1 = v)),
          _radioBlock('When do you expect Bitcoin PQ migration to reach 50%?', _o2, _q2, (v) => setState(() => _q2 = v)),
          _radioBlock('What share of Bitcoin value is at risk?', _o3, _q3, (v) => setState(() => _q3 = v)),
          _radioBlock('How confident is ecosystem coordination?', _o4, _q4, (v) => setState(() => _q4 = v)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _submitted = true),
            child: const Text('Get assessment'),
          ),
          if (_submitted) ...[
            const SizedBox(height: 20),
            _resultCard(),
          ],
        ],
      ),
    );
  }

  Widget _resultCard() {
    final score = _score();
    final band = quickCheckBand(score);
    Color c = AppColors.migration;
    if (band.contains('Moderate')) c = AppColors.amber;
    if (band.contains('High')) c = AppColors.risk;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$band (score $score/8)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c),
            ),
            const SizedBox(height: 8),
            Text(
              score <= 2
                  ? 'Your assumptions suggest the race is manageable.'
                  : score <= 5
                      ? 'Some tension between quantum timelines and migration.'
                      : 'Quantum could outpace migration under your assumptions.',
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioBlock(String title, List<String> opts, int value, void Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 8),
          ...List.generate(opts.length, (i) {
            return RadioListTile<int>(
              dense: true,
              value: i,
              groupValue: value,
              onChanged: (v) => onChanged(v!),
              title: Text(opts[i], style: const TextStyle(fontSize: 13)),
            );
          }),
        ],
      ),
    );
  }
}

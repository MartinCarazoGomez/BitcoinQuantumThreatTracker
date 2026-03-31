import 'package:flutter/material.dart';

import '../engine/risk_engine.dart';
import '../theme/app_theme.dart';

class QuickCheckScreen extends StatefulWidget {
  const QuickCheckScreen({super.key});

  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

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

  void _submitAssessment() {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 24;
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Risk Check')),
      body: ListView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
        children: [
          Text(
            'Four questions → a risk band.',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 16),
          _radioBlock('When do you expect quantum computers to reach 50% capability (break ECDSA)?', _o1, _q1, (v) => setState(() => _q1 = v)),
          _radioBlock('When do you expect Bitcoin migration to post-quantum to reach 50%?', _o2, _q2, (v) => setState(() => _q2 = v)),
          _radioBlock('What share of Bitcoin value do you consider at risk?', _o3, _q3, (v) => setState(() => _q3 = v)),
          _radioBlock('How confident is ecosystem coordination on migration?', _o4, _q4, (v) => setState(() => _q4 = v)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitAssessment,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.amber,
                foregroundColor: const Color(0xFF0f172a),
              ),
              child: const Text('Get assessment'),
            ),
          ),
          if (_submitted) ...[
            const SizedBox(height: 20),
            KeyedSubtree(
              key: _resultKey,
              child: _resultCard(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard() {
    final score = _score();
    final band = quickCheckBand(score);

    late final Color bandColor;
    late final Color bg;
    late final Color border;
    late final String headline;
    late final String followUp;

    if (score <= 2) {
      bandColor = const Color(0xFF4ade80);
      bg = const Color(0xFF14532d).withValues(alpha: 0.45);
      border = const Color(0xFF22c55e).withValues(alpha: 0.45);
      headline = 'Low risk — migration likely ahead of quantum on your assumptions.';
      followUp = 'Try the Simulator for more scenarios.';
    } else if (score <= 5) {
      bandColor = AppColors.amber;
      bg = const Color(0xFF713f12).withValues(alpha: 0.4);
      border = AppColors.amber.withValues(alpha: 0.45);
      headline = 'Moderate risk — quantum and migration are in tension.';
      followUp = 'Simulator: tune migration timing.';
    } else {
      bandColor = AppColors.risk;
      bg = const Color(0xFF7f1d1d).withValues(alpha: 0.45);
      border = AppColors.risk.withValues(alpha: 0.45);
      headline = 'High risk — quantum could lead migration on your assumptions.';
      followUp = 'Simulator: pessimistic preset + sliders.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bg,
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$band (score $score/8)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: bandColor),
              ),
              const SizedBox(height: 10),
              Text(headline, style: const TextStyle(height: 1.45, color: AppColors.text)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1e3a5f).withValues(alpha: 0.45),
            border: Border.all(color: AppColors.quantum.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.quantum.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Expanded(child: Text(followUp, style: const TextStyle(height: 1.45, fontSize: 13, color: AppColors.text))),
            ],
          ),
        ),
      ],
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

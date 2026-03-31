import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../content/app_strings.dart';
import '../engine/risk_engine.dart';
import '../theme/app_theme.dart';

/// Rounds [value] to [n] significant digits (for tooltips).
double _roundToSignificantDigits(double value, int n) {
  if (value == 0) return 0;
  final d = log(value.abs()) / ln10;
  final magnitude = d.floor();
  final scale = pow(10.0, n - 1 - magnitude);
  return (value * scale).round() / scale;
}

/// Formats [x] as a decimal string with exactly three significant figures.
String _formatSig3(double x) {
  if (x == 0) return '0';
  final r = _roundToSignificantDigits(x, 3);
  final mag = (log(r.abs()) / ln10).floor();
  final decimals = max(0, 2 - mag);
  return r.toStringAsFixed(decimals);
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  String _scenario = 'Moderate';
  String _strategy = 'Hybrid';
  late Map<String, dynamic> _params;
  late double _scrubYear;
  String _sensParam = 'migration_start';

  static const _scenarioShort = ['Opt', 'Mod', 'Pess'];

  /// Must match [LineChartData.titlesData] left / bottom reserved sizes (plot area inset).
  static const _chartPlotLeftInset = 38.0;
  static const _chartPlotBottomInset = 26.0;

  @override
  void initState() {
    super.initState();
    _params = Map<String, dynamic>.from(scenarioDefaults(_scenario));
    _scrubYear = kYears[kYears.length ~/ 2].toDouble();
  }

  void _applyScenario(String name) {
    setState(() {
      _scenario = name;
      _params = Map<String, dynamic>.from(scenarioDefaults(name));
    });
  }

  /// Snaps a chart x-coordinate to the nearest year index in [kYears].
  int _nearestYearIndex(double x) {
    final clamped = x.clamp(kYears.first.toDouble(), kYears.last.toDouble());
    var best = 0;
    var bestD = (kYears[0] - clamped).abs();
    for (var j = 1; j < kYears.length; j++) {
      final d = (kYears[j] - clamped).abs();
      if (d < bestD) {
        bestD = d;
        best = j;
      }
    }
    return best;
  }

  CurveResult _curves() {
    return buildCurves(
      years: kYears,
      quantumSteepness: _params['quantum_steepness'] as double,
      breakYear: _params['break_year'] as int,
      migrationStart: _params['migration_start'] as int,
      migrationSpeed: _params['migration_speed'] as double,
      vulnerableShare: _params['vulnerable_share'] as double,
      strategy: _strategy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final curves = _curves();
    final peak = curves.risk.reduce(max);
    final crit = detectCriticalDeadline(
      kYears,
      curves.risk,
      curves.quantum,
      curves.migration,
      _params['crisis_threshold'] as double,
    );
    final m50 = firstYearReachingThreshold(kYears, curves.migration, 0.5);
    final q50 = firstYearReachingThreshold(kYears, curves.quantum, 0.5);
    final verdict = generateVerdict(peak, crit.year, m50, q50);
    final rec = makeRecommendation(_scenario, verdict, crit.year, m50, q50);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Simulator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Race Between Quantum Capability and Bitcoin Migration',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the chart to select a year. Q/M/R (0–1 scale) appear on the chart to 3 significant figures.',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 300, child: _mainLineChart(curves, crit)),
          const SizedBox(height: 12),
          _metrics(peak, crit, m50, q50, verdict),
          const SizedBox(height: 10),
          _verdictBanner(verdict, rec),
          const SizedBox(height: 16),
          _paramsCard(),
          const SizedBox(height: 16),
          const Text('Chart guide', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text)),
          const SizedBox(height: 8),
          ..._chartGuideBulletWidgets(),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF1e3a5f).withValues(alpha: 0.55),
              border: Border.all(color: AppColors.quantum.withValues(alpha: 0.25)),
            ),
            child: Text(
              'Logic: ${crit.reason}',
              style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text),
            ),
          ),
          const SizedBox(height: 16),
          _heroCard(),
          const SizedBox(height: 12),
          _topExpansionTile(
            title: 'Compare',
            subtitle: 'Preset scenarios vs your current strategy',
            child: _comparePanel(),
          ),
          _topExpansionTile(
            title: 'Sensitivity',
            subtitle: 'Peak risk vs one parameter',
            child: _sensitivityPanel(),
            maintainState: true,
          ),
          _topExpansionTile(
            title: 'Summary',
            subtitle: 'Recommendation and CSV export',
            child: _summaryPanel(verdict, rec, curves),
          ),
        ],
      ),
    );
  }

  Widget _topExpansionTile({
    required String title,
    required String subtitle,
    required Widget child,
    bool maintainState = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        maintainState: maintainState,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.9))),
        children: [child],
      ),
    );
  }

  /// Bullet paragraphs for the chart guide (below the main chart).
  List<Widget> _chartGuideBulletWidgets() {
    return [
      for (final line in AppStrings.chartGuideBullets)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Builder(
            builder: (context) {
              const sep = ' — ';
              final i = line.indexOf(sep);
              if (i < 0) {
                return Text(line, style: const TextStyle(height: 1.45, color: AppColors.text));
              }
              final head = line.substring(0, i);
              final tail = line.substring(i + sep.length);
              return Text.rich(
                TextSpan(
                  style: const TextStyle(height: 1.45),
                  children: [
                    TextSpan(text: head, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                    const TextSpan(text: sep),
                    TextSpan(text: tail, style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95))),
                  ],
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _paramsCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Parameters', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Scenario presets and sliders'),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (var j = 0; j < scenarios.length; j++)
                  ChoiceChip(
                    label: Text(_scenarioShort[j]),
                    selected: _scenario == scenarios[j],
                    onSelected: (_) => _applyScenario(scenarios[j]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Optimistic · Moderate · Pessimistic',
              style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _strategy,
              decoration: const InputDecoration(labelText: 'Post-quantum strategy'),
              items: strategies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _strategy = v ?? _strategy),
            ),
            if (AppStrings.strategyNotes[_strategy] != null) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.strategyNotes[_strategy]!,
                style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.9)),
              ),
            ],
            _slider('Quantum steepness', 'quantum_steepness', 0.15, 0.80),
            _slider('Quantum break year (50%)', 'break_year', 2028, 2050, isInt: true),
            _slider('Migration start year', 'migration_start', 2026, 2050, isInt: true),
            _slider('Migration speed', 'migration_speed', 0.15, 0.90),
            _slider('Vulnerable share', 'vulnerable_share', 0.20, 1.00),
            _slider('Crisis threshold', 'crisis_threshold', 0.10, 0.80),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface2.withValues(alpha: 0.75),
            AppColors.bg.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.22)),
      ),
      child: Text(
        'Explore the timing race between quantum capability and Bitcoin migration. '
        'Use Compare, Sensitivity, and Summary below for preset comparison, one-parameter sweeps, and export—they expand on tap.',
        style: TextStyle(color: AppColors.muted.withValues(alpha: 0.98), height: 1.55, fontSize: 14),
      ),
    );
  }

  Widget _verdictBanner(String verdict, String rec) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF14532d).withValues(alpha: 0.45),
        border: Border.all(color: const Color(0xFF22c55e).withValues(alpha: 0.35)),
      ),
      child: Text(
        '$verdict — $rec',
        style: const TextStyle(height: 1.45, color: Color(0xFFbbf7d0), fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Reads Q/M/R at [_scrubYear] and draws a small legend inside the plot (matches fl_chart axis insets).
  Widget _chartValueOverlay(double qv, double mv, double rv) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final left = _chartPlotLeftInset;
        final plotW = w - left;
        final plotH = h - _chartPlotBottomInset;
        if (plotW <= 8 || plotH <= 8) return const SizedBox.shrink();

        final minXd = kYears.first.toDouble();
        final maxXd = kYears.last.toDouble();
        final cx = left + (_scrubYear - minXd) / (maxXd - minXd) * plotW;

        const labelW = 120.0;
        var boxLeft = cx + 8;
        if (boxLeft + labelW > left + plotW - 4) {
          boxLeft = cx - 8 - labelW;
        }
        boxLeft = boxLeft.clamp(left + 4, left + plotW - labelW);

        return Stack(
          children: [
            Positioned(
              left: boxLeft,
              top: 6,
              child: Container(
                constraints: const BoxConstraints(maxWidth: labelW),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Year ${_scrubYear.round()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.muted.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Q ${_formatSig3(qv)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.quantum, fontWeight: FontWeight.w600, height: 1.25),
                    ),
                    Text(
                      'M ${_formatSig3(mv)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.migration, fontWeight: FontWeight.w600, height: 1.25),
                    ),
                    Text(
                      'R ${_formatSig3(rv)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.risk, fontWeight: FontWeight.w600, height: 1.25),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mainLineChart(CurveResult curves, CriticalResult crit) {
    final yi = kYears.indexWhere((y) => y == _scrubYear.round());
    final i = yi >= 0 ? yi : _nearestYearIndex(_scrubYear);
    final qv = curves.quantum[i];
    final mv = curves.migration[i];
    final rv = curves.risk[i];

    final crisis = _params['crisis_threshold'] as double;
    final spotsQ = [for (var j = 0; j < kYears.length; j++) FlSpot(kYears[j].toDouble(), curves.quantum[j])];
    final spotsM = [for (var j = 0; j < kYears.length; j++) FlSpot(kYears[j].toDouble(), curves.migration[j])];
    final spotsR = [for (var j = 0; j < kYears.length; j++) FlSpot(kYears[j].toDouble(), curves.risk[j])];

    final vertical = <VerticalLine>[
      VerticalLine(
        x: _scrubYear,
        color: AppColors.muted.withValues(alpha: 0.4),
        strokeWidth: 1,
      ),
    ];
    if (crit.year != null) {
      vertical.add(
        VerticalLine(
          x: crit.year!.toDouble(),
          color: const Color(0xFFfcd34d),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      );
    }

    final horizontal = <HorizontalLine>[
      HorizontalLine(
        y: crisis,
        color: AppColors.risk.withValues(alpha: 0.7),
        strokeWidth: 1,
        dashArray: [6, 4],
      ),
    ];

    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: spotsQ,
        color: AppColors.quantum,
        barWidth: 2.5,
        isCurved: true,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppColors.quantum.withValues(alpha: 0.2), AppColors.quantum.withValues(alpha: 0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: spotsM,
        color: AppColors.migration,
        barWidth: 2.5,
        isCurved: true,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppColors.migration.withValues(alpha: 0.2), AppColors.migration.withValues(alpha: 0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: spotsR,
        color: AppColors.risk,
        barWidth: 3,
        isCurved: true,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppColors.risk.withValues(alpha: 0.25), AppColors.risk.withValues(alpha: 0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: const FlDotData(show: false),
      ),
    ];

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        LineChart(
          LineChartData(
        minX: kYears.first.toDouble(),
        maxX: kYears.last.toDouble(),
        minY: 0,
        maxY: 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06)),
          getDrawingVerticalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _chartPlotLeftInset,
              interval: 0.2,
              getTitlesWidget: (value, meta) {
                final p = (value.clamp(0.0, 1.0) * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '$p%',
                    style: const TextStyle(fontSize: 10, color: AppColors.muted),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _chartPlotBottomInset,
              interval: 5,
              getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        extraLinesData: ExtraLinesData(verticalLines: vertical, horizontalLines: horizontal),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => List<LineTooltipItem?>.filled(touchedSpots.length, null),
          ),
          getTouchedSpotIndicator: (barData, indexes) {
            return [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(
                    color: AppColors.muted.withValues(alpha: 0.55),
                    strokeWidth: 1.25,
                  ),
                  const FlDotData(show: false),
                ),
            ];
          },
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response == null) return;
            final spots = response.lineBarSpots;
            if (spots == null || spots.isEmpty) return;
            final xi = _nearestYearIndex(spots.first.x);
            setState(() {
              _scrubYear = kYears[xi].toDouble();
            });
          },
        ),
      ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _chartValueOverlay(qv, mv, rv),
          ),
        ),
      ],
    );
  }

  Widget _metrics(double peak, CriticalResult crit, int? m50, int? q50, String verdict) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metricChip('Peak risk', peak.toStringAsFixed(2)),
        _metricChip('Critical yr', crit.year?.toString() ?? '—'),
        _metricChip('Mig 50%', m50?.toString() ?? '—'),
        _metricChip('Quantum 50%', q50?.toString() ?? '—'),
        _metricChip('Buffer', bufferLabel(m50, q50)),
        _metricChip('Verdict', verdict),
      ],
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.amber, fontSize: 14)),
        ],
      ),
    );
  }

  /// Continuous slider; values snap to match Streamlit (2 decimals / whole years). Avoids broken discrete `divisions` on web.
  Widget _slider(String label, String key, double min, double max, {bool isInt = false}) {
    final v = _params[key];
    double cur = isInt ? (v as int).toDouble() : (v as num).toDouble();
    cur = cur.clamp(min, max);
    final minI = min.round();
    final maxI = max.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${isInt ? cur.round() : cur.toStringAsFixed(2)}'),
        Slider(
          value: cur,
          min: min,
          max: max,
          onChanged: (nv) {
            setState(() {
              if (isInt) {
                _params[key] = nv.round().clamp(minI, maxI);
              } else {
                final x = nv.clamp(min, max);
                _params[key] = double.parse(x.toStringAsFixed(2));
              }
            });
          },
        ),
      ],
    );
  }

  Widget _comparePanel() {
    final rows = runScenarioComparison(kYears, _strategy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Preset scenarios vs your current strategy.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Scenario')),
              DataColumn(label: Text('Peak risk')),
              DataColumn(label: Text('Critical year')),
              DataColumn(label: Text('Migration 50%')),
              DataColumn(label: Text('Quantum 50%')),
              DataColumn(label: Text('Buffer')),
              DataColumn(label: Text('Verdict')),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(Text(r.scenario)),
                    DataCell(Text(r.peakRisk.toStringAsFixed(2))),
                    DataCell(Text(r.criticalYear?.toString() ?? '—')),
                    DataCell(Text(r.migration50?.toString() ?? '—')),
                    DataCell(Text(r.quantum50?.toString() ?? '—')),
                    DataCell(Text(bufferLabel(r.migration50, r.quantum50))),
                    DataCell(Text(r.verdict, style: const TextStyle(fontSize: 11))),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preset defaults for each scenario with your current migration strategy.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _sensitivityPanel() {
    final (xVals, yVals) = runSensitivityAnalysis(_params, kYears, _sensParam, _strategy);
    final spots = [for (var i = 0; i < xVals.length; i++) FlSpot(xVals[i], yVals[i])];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: _sensParam,
          decoration: const InputDecoration(labelText: 'Parameter to sweep'),
          items: const [
            DropdownMenuItem(value: 'migration_start', child: Text('Migration start')),
            DropdownMenuItem(value: 'migration_speed', child: Text('Migration speed')),
            DropdownMenuItem(value: 'break_year', child: Text('Break year')),
            DropdownMenuItem(value: 'vulnerable_share', child: Text('Vulnerable share')),
          ],
          onChanged: (v) => setState(() => _sensParam = v ?? _sensParam),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 1,
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  isCurved: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.accent.withValues(alpha: 0.2), AppColors.accent.withValues(alpha: 0.02)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(show: true, getDotPainter: (s, p, i, c) => FlDotCirclePainter(radius: 3, color: AppColors.accent)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Steep slopes = highly sensitive; flat regions = more robust to changes.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _summaryPanel(String verdict, String rec, CurveResult curves) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Recommendation: $rec', style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Text(
          'Assumptions — Scenario model, not prediction. Conclusions depend on break-year timing, migration speed, and vulnerable share.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            final sb = StringBuffer();
            sb.writeln('Year,Quantum capability,Migration progress,Risk');
            for (var j = 0; j < kYears.length; j++) {
              sb.writeln('${kYears[j]},${curves.quantum[j]},${curves.migration[j]},${curves.risk[j]}');
            }
            Share.share(sb.toString(), subject: 'quantum_migration_curves_${_scenario.toLowerCase()}.csv');
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download curve data (CSV)'),
        ),
      ],
    );
  }
}

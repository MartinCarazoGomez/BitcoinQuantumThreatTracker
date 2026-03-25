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

class _SimulatorScreenState extends State<SimulatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _scenario = 'Moderate';
  String _strategy = 'Hybrid';
  late Map<String, dynamic> _params;
  late double _scrubYear;
  bool _showQ = true;
  bool _showM = true;
  bool _showR = true;
  bool _showDanger = true;
  bool _showCrit = true;
  String _sensParam = 'migration_start';

  static const _scenarioShort = ['Opt', 'Mod', 'Pess'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _params = Map<String, dynamic>.from(scenarioDefaults(_scenario));
    _scrubYear = kYears[kYears.length ~/ 2].toDouble();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyScenario(String name) {
    setState(() {
      _scenario = name;
      _params = Map<String, dynamic>.from(scenarioDefaults(name));
    });
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
    final idx = kYears.indexWhere((y) => y >= _scrubYear.round());
    final i = idx < 0 ? kYears.length - 1 : idx;
    final qv = curves.quantum[i];
    final mv = curves.migration[i];
    final rv = curves.risk[i];

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Simulator')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                _heroCard(),
                const SizedBox(height: 12),
                _paramsCard(),
                const SizedBox(height: 12),
                _metrics(peak, crit, m50, q50, verdict),
                const SizedBox(height: 10),
                _verdictBanner(verdict, rec),
                const SizedBox(height: 16),
                Text(
                  'Scrub year to explore',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _scrubYear.clamp(kYears.first.toDouble(), kYears.last.toDouble()),
                  min: kYears.first.toDouble(),
                  max: kYears.last.toDouble(),
                  label: _scrubYear.round().toString(),
                  onChanged: (v) => setState(() => _scrubYear = v.round().toDouble().clamp(
                        kYears.first.toDouble(),
                        kYears.last.toDouble(),
                      )),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(label: const Text('Quantum'), selected: _showQ, onSelected: (v) => setState(() => _showQ = v)),
                    FilterChip(label: const Text('Migration'), selected: _showM, onSelected: (v) => setState(() => _showM = v)),
                    FilterChip(label: const Text('Risk'), selected: _showR, onSelected: (v) => setState(() => _showR = v)),
                    FilterChip(label: const Text('Danger zone'), selected: _showDanger, onSelected: (v) => setState(() => _showDanger = v)),
                    FilterChip(label: const Text('Critical line'), selected: _showCrit, onSelected: (v) => setState(() => _showCrit = v)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Race Between Quantum Capability and Bitcoin Migration',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Y-axis is 0–100% for every curve: quantum capability, migration progress, and risk—same scale, different meaning per color.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.95), height: 1.4),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 300, child: _mainLineChart(curves, crit)),
                const SizedBox(height: 8),
                Text(
                  'At ${_scrubYear.round()}: Q ${(qv * 100).round()}% · M ${(mv * 100).round()}% · R ${(rv * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Material(
            color: AppColors.surface.withValues(alpha: 0.5),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Chart Guide'),
                Tab(text: 'Compare'),
                Tab(text: 'Sensitivity'),
                Tab(text: 'Summary'),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: [
                _chartGuideTab(crit),
                _compareTab(),
                _sensitivityTab(),
                _summaryTab(verdict, rec, curves),
              ],
            ),
          ),
        ],
      ),
    );
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
            _slider('Quantum break year (50%)', 'break_year', 2032, 2050, isInt: true),
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
        'Adjust parameters below, scrub the chart by year, and compare scenarios in the tabs.',
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

  Widget _mainLineChart(CurveResult curves, CriticalResult crit) {
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
    if (_showCrit && crit.year != null) {
      vertical.add(
        VerticalLine(
          x: crit.year!.toDouble(),
          color: const Color(0xFFfcd34d),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      );
    }

    final horizontal = <HorizontalLine>[];
    if (_showDanger) {
      horizontal.add(
        HorizontalLine(
          y: crisis,
          color: AppColors.risk.withValues(alpha: 0.7),
          strokeWidth: 1,
          dashArray: [6, 4],
        ),
      );
    }

    final bars = <LineChartBarData>[];
    final lineNames = <String>[];
    if (_showQ) {
      lineNames.add('Quantum');
      bars.add(
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
      );
    }
    if (_showM) {
      lineNames.add('Migration');
      bars.add(
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
      );
    }
    if (_showR) {
      lineNames.add('Risk');
      bars.add(
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
      );
    }

    return LineChart(
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
              reservedSize: 38,
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
              reservedSize: 26,
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
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              if (spots.isEmpty) return [];
              final year = spots.first.x.round();
              final sb = StringBuffer('Year $year');
              for (final s in spots) {
                final idx = s.barIndex;
                final label = idx >= 0 && idx < lineNames.length ? lineNames[idx] : 'Series ${idx + 1}';
                sb
                  ..writeln()
                  ..write('$label: ${_formatSig3(s.y)}');
              }
              return [
                LineTooltipItem(
                  sb.toString(),
                  const TextStyle(color: Colors.white, fontSize: 11, height: 1.35),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  Widget _chartGuideTab(CriticalResult crit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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

  Widget _compareTab() {
    final rows = runScenarioComparison(kYears, _strategy);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Preset scenarios vs your current strategy.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
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
        const SizedBox(height: 10),
        const Text(
          'Preset defaults for each scenario with your current migration strategy.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _sensitivityTab() {
    final (xVals, yVals) = runSensitivityAnalysis(_params, kYears, _sensParam, _strategy);
    final spots = [for (var i = 0; i < xVals.length; i++) FlSpot(xVals[i], yVals[i])];
    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
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

  Widget _summaryTab(String verdict, String rec, CurveResult curves) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recommendation: $rec', style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Text(
          'Assumptions — Scenario model, not prediction. Conclusions depend on break-year timing, migration speed, and vulnerable share.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
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

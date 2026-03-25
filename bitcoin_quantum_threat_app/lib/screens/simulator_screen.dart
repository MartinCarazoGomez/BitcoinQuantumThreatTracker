import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../engine/risk_engine.dart';
import '../theme/app_theme.dart';

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
  double _scrubYear = 2040;
  bool _showQ = true;
  bool _showM = true;
  bool _showR = true;
  bool _showDanger = true;
  bool _showCrit = true;
  String _sensParam = 'migration_start';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _params = Map<String, dynamic>.from(scenarioDefaults(_scenario));
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
      appBar: AppBar(
        title: const Text('Risk Simulator'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Compare'),
            Tab(text: 'Sensitivity'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _chartTab(
            curves: curves,
            peak: peak,
            crit: crit,
            verdict: verdict,
            rec: rec,
            m50: m50,
            q50: q50,
            qv: qv,
            mv: mv,
            rv: rv,
            i: i,
          ),
          _compareTab(),
          _sensitivityTab(),
          _summaryTab(verdict, rec, curves),
        ],
      ),
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

  Widget _chartTab({
    required CurveResult curves,
    required double peak,
    required CriticalResult crit,
    required String verdict,
    required String rec,
    required int? m50,
    required int? q50,
    required double qv,
    required double mv,
    required double rv,
    required int i,
  }) {
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
    if (_showQ) {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Explore the timing race between quantum capability and Bitcoin migration.',
          style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95)),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          initiallyExpanded: true,
          title: const Text('Parameters', style: TextStyle(fontWeight: FontWeight.w700)),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final s in scenarios)
                  ChoiceChip(
                    label: Text(s.substring(0, 3)),
                    selected: _scenario == s,
                    onSelected: (_) => _applyScenario(s),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _strategy,
              decoration: const InputDecoration(labelText: 'Post-quantum strategy'),
              items: strategies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _strategy = v ?? _strategy),
            ),
            _slider('Quantum steepness', 'quantum_steepness', 0.15, 0.80, 100),
            _slider('Quantum break year (50%)', 'break_year', 2032, 2050, 1, isInt: true),
            _slider('Migration start year', 'migration_start', 2026, 2050, 1, isInt: true),
            _slider('Migration speed', 'migration_speed', 0.15, 0.90, 100),
            _slider('Vulnerable share', 'vulnerable_share', 0.20, 1.00, 100),
            _slider('Crisis threshold', 'crisis_threshold', 0.10, 0.80, 100),
          ],
        ),
        const SizedBox(height: 12),
        _metrics(peak, crit, m50, q50, verdict),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('$verdict — $rec', style: const TextStyle(height: 1.4)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Scrub year', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9))),
        Slider(
          value: _scrubYear,
          min: kYears.first.toDouble(),
          max: kYears.last.toDouble(),
          divisions: kYears.length - 1,
          label: _scrubYear.round().toString(),
          onChanged: (v) => setState(() => _scrubYear = v),
        ),
        Wrap(
          spacing: 6,
          children: [
            FilterChip(label: const Text('Quantum'), selected: _showQ, onSelected: (v) => setState(() => _showQ = v)),
            FilterChip(label: const Text('Migration'), selected: _showM, onSelected: (v) => setState(() => _showM = v)),
            FilterChip(label: const Text('Risk'), selected: _showR, onSelected: (v) => setState(() => _showR = v)),
            FilterChip(label: const Text('Danger zone'), selected: _showDanger, onSelected: (v) => setState(() => _showDanger = v)),
            FilterChip(label: const Text('Critical line'), selected: _showCrit, onSelected: (v) => setState(() => _showCrit = v)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: LineChart(
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
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
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
              lineTouchData: LineTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'At ${_scrubYear.round()}: Q=${qv.toStringAsFixed(2)} M=${mv.toStringAsFixed(2)} R=${rv.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Text('Logic: ${crit.reason}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _slider(String label, String key, double min, double max, int divisions, {bool isInt = false}) {
    final v = _params[key];
    final double cur = isInt ? (v as int).toDouble() : v as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${isInt ? cur.round() : cur.toStringAsFixed(2)}'),
        Slider(
          value: cur.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: (nv) {
            setState(() {
              _params[key] = isInt ? nv.round() : double.parse(nv.toStringAsFixed(2));
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
              DataColumn(label: Text('Peak')),
              DataColumn(label: Text('Crit yr')),
              DataColumn(label: Text('Mig50')),
              DataColumn(label: Text('Q50')),
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
                    DataCell(Text(r.verdict, style: const TextStyle(fontSize: 11))),
                  ],
                ),
            ],
          ),
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
          height: 280,
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
                  dotData: FlDotData(show: true, getDotPainter: (s, p, i, c) => FlDotCirclePainter(radius: 3, color: AppColors.accent)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Steep slopes = sensitive; flat = more robust.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  Widget _summaryTab(String verdict, String rec, CurveResult curves) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recommendation: $rec', style: const TextStyle(height: 1.45)),
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
          icon: const Icon(Icons.ios_share),
          label: const Text('Share curve data (CSV)'),
        ),
      ],
    );
  }
}

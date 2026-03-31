import 'dart:math';

/// Mirrors `app.py` scenario and curve logic (2026–2055 horizon).
final List<int> kYears = List<int>.generate(30, (i) => 2026 + i);

const scenarios = ['Optimistic', 'Moderate', 'Pessimistic'];
const strategies = ['SPHINCS+', 'Lamport', 'Hybrid'];

double logisticCurve(double x, double midpoint, double steepness) {
  return 1.0 / (1.0 + exp(-steepness * (x - midpoint)));
}

Map<String, double> strategyEffects(String strategy) {
  switch (strategy) {
    case 'SPHINCS+':
      return {'speed_multiplier': 0.90, 'friction_years': 1.0};
    case 'Lamport':
      return {'speed_multiplier': 0.78, 'friction_years': 2.0};
    case 'Hybrid':
    default:
      return {'speed_multiplier': 1.10, 'friction_years': 0.0};
  }
}

/// Preset quantum midpoints align with FNCE313 deck Q-Day bands: Optimistic 2040+,
/// Moderate 2033+, Pessimistic 2029–2031 (here: 2030 midpoint).
Map<String, dynamic> scenarioDefaults(String name) {
  switch (name) {
    case 'Optimistic':
      return {
        'quantum_steepness': 0.30,
        'break_year': 2040,
        'migration_start': 2030,
        'migration_speed': 0.55,
        'vulnerable_share': 0.55,
        'crisis_threshold': 0.35,
      };
    case 'Pessimistic':
      return {
        'quantum_steepness': 0.48,
        'break_year': 2030,
        'migration_start': 2036,
        'migration_speed': 0.30,
        'vulnerable_share': 0.85,
        'crisis_threshold': 0.45,
      };
    case 'Moderate':
    default:
      return {
        'quantum_steepness': 0.38,
        'break_year': 2033,
        'migration_start': 2033,
        'migration_speed': 0.42,
        'vulnerable_share': 0.70,
        'crisis_threshold': 0.40,
      };
  }
}

class CurveResult {
  CurveResult({
    required this.quantum,
    required this.migration,
    required this.risk,
  });
  final List<double> quantum;
  final List<double> migration;
  final List<double> risk;
}

CurveResult buildCurves({
  required List<int> years,
  required double quantumSteepness,
  required int breakYear,
  required int migrationStart,
  required double migrationSpeed,
  required double vulnerableShare,
  required String strategy,
}) {
  final se = strategyEffects(strategy);
  final friction = se['friction_years']!;
  final speedMult = se['speed_multiplier']!;
  final quantum = years
      .map((y) => logisticCurve(
            y.toDouble(),
            breakYear.toDouble(),
            quantumSteepness,
          ))
      .toList();
  final migrationMid = migrationStart + friction;
  final adjSpeed = migrationSpeed * speedMult;
  final migration = years
      .map((y) => logisticCurve(
            y.toDouble(),
            migrationMid,
            adjSpeed,
          ))
      .toList();
  final risk = List<double>.generate(years.length, (i) {
    final raw = quantum[i] * (1.0 - migration[i]);
    return (raw * vulnerableShare).clamp(0.0, 1.0);
  });
  return CurveResult(quantum: quantum, migration: migration, risk: risk);
}

int? firstYearReachingThreshold(List<int> years, List<double> series, double threshold) {
  for (var i = 0; i < series.length; i++) {
    if (series[i] >= threshold) return years[i];
  }
  return null;
}

class CriticalResult {
  CriticalResult(this.year, this.reason);
  final int? year;
  final String reason;
}

CriticalResult detectCriticalDeadline(
  List<int> years,
  List<double> risk,
  List<double> quantum,
  List<double> migration,
  double crisisThreshold,
) {
  final ty = firstYearReachingThreshold(years, risk, crisisThreshold);
  if (ty != null) {
    return CriticalResult(ty, 'Risk crosses crisis threshold');
  }
  for (var i = 0; i < years.length; i++) {
    if (quantum[i] - migration[i] > 0.20 && quantum[i] > 0.60) {
      return CriticalResult(years[i], 'Quantum lead over migration becomes dangerous');
    }
  }
  return CriticalResult(null, 'No critical deadline detected in horizon');
}

String generateVerdict(
  double peakRisk,
  int? criticalYear,
  int? migration50,
  int? quantum50,
) {
  if (peakRisk < 0.25 && criticalYear == null) return 'Safe for now';
  if (criticalYear == null &&
      migration50 != null &&
      quantum50 != null &&
      migration50 <= quantum50) {
    return 'Manageable transition';
  }
  if (criticalYear != null && peakRisk < 0.45) return 'High coordination risk';
  if (quantum50 != null && migration50 != null && migration50 > quantum50 + 2) {
    return 'Crisis if delayed';
  }
  return 'Manageable transition';
}

String makeRecommendation(
  String scenario,
  String verdict,
  int? criticalYear,
  int? migration50,
  int? quantum50,
) {
  final s = scenario.toLowerCase();
  if (criticalYear != null) {
    final latestStart = max(2026, criticalYear - 4);
    return 'Under $s assumptions, migration should begin by '
        '$latestStart to reduce crisis risk before $criticalYear.';
  }
  if (migration50 != null && quantum50 != null) {
    if (migration50 <= quantum50) {
      return 'Under $s assumptions, current migration pace appears '
          'manageable if coordination remains strong.';
    }
    return 'Under $s assumptions, migration timing should be pulled '
        'forward to at least match quantum progress by $quantum50.';
  }
  return 'Under $s assumptions, continue monitoring and update assumptions annually.';
}

String bufferLabel(int? migration50, int? quantum50) {
  if (migration50 == null || quantum50 == null) return 'N/A';
  final diff = quantum50 - migration50;
  if (diff > 0) return 'Mig +${diff}yr';
  if (diff < 0) return 'Quantum +${-diff}yr';
  return 'Tied';
}

class ScenarioRow {
  ScenarioRow({
    required this.scenario,
    required this.peakRisk,
    required this.criticalYear,
    required this.migration50,
    required this.quantum50,
    required this.verdict,
  });
  final String scenario;
  final double peakRisk;
  final int? criticalYear;
  final int? migration50;
  final int? quantum50;
  final String verdict;
}

List<ScenarioRow> runScenarioComparison(List<int> years, String strategy) {
  final out = <ScenarioRow>[];
  for (final name in scenarios) {
    final p = scenarioDefaults(name);
    final curves = buildCurves(
      years: years,
      quantumSteepness: p['quantum_steepness'] as double,
      breakYear: p['break_year'] as int,
      migrationStart: p['migration_start'] as int,
      migrationSpeed: p['migration_speed'] as double,
      vulnerableShare: p['vulnerable_share'] as double,
      strategy: strategy,
    );
    final crit = detectCriticalDeadline(
      years,
      curves.risk,
      curves.quantum,
      curves.migration,
      p['crisis_threshold'] as double,
    );
    final m50 = firstYearReachingThreshold(years, curves.migration, 0.5);
    final q50 = firstYearReachingThreshold(years, curves.quantum, 0.5);
    final peak = curves.risk.reduce(max);
    out.add(ScenarioRow(
      scenario: name,
      peakRisk: peak,
      criticalYear: crit.year,
      migration50: m50,
      quantum50: q50,
      verdict: generateVerdict(peak, crit.year, m50, q50),
    ));
  }
  return out;
}

/// Returns (xValues, peakRisks) for sensitivity chart.
(List<double>, List<double>) runSensitivityAnalysis(
  Map<String, dynamic> baseParams,
  List<int> years,
  String parameterName,
  String strategy,
) {
  final ranges = <String, List<double>>{
    'migration_start': [for (var y = 2028; y <= 2040; y++) y.toDouble()],
    'migration_speed': _linspace(0.20, 0.80, 16),
    'break_year': [for (var y = 2028; y <= 2047; y++) y.toDouble()],
    'vulnerable_share': _linspace(0.40, 0.95, 12),
  };
  final xVals = ranges[parameterName]!;
  final peakVals = <double>[];
  for (final xv in xVals) {
    final params = Map<String, dynamic>.from(baseParams);
    if (parameterName == 'migration_speed' || parameterName == 'vulnerable_share') {
      params[parameterName] = xv;
    } else {
      params[parameterName] = xv.round();
    }
    final q = buildCurves(
      years: years,
      quantumSteepness: params['quantum_steepness'] as double,
      breakYear: params['break_year'] as int,
      migrationStart: params['migration_start'] as int,
      migrationSpeed: params['migration_speed'] as double,
      vulnerableShare: params['vulnerable_share'] as double,
      strategy: strategy,
    );
    peakVals.add(q.risk.reduce(max));
  }
  return (xVals, peakVals);
}

List<double> _linspace(double a, double b, int n) {
  if (n < 2) return [a];
  final step = (b - a) / (n - 1);
  return [for (var i = 0; i < n; i++) double.parse((a + step * i).toStringAsFixed(2))];
}

/// Quick check score 0–8 from four choices (indices 0,1,2 each).
int quickCheckScore(int q1, int q2, int q3, int q4) {
  return q1 + q2 + q3 + q4;
}

String quickCheckBand(int score) {
  if (score <= 2) return 'Low risk';
  if (score <= 5) return 'Moderate risk';
  return 'High risk';
}

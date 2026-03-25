import 'dart:math';

/// Conceptual curves for News "The race" chart (same formulas as `app.py`).
List<double> raceYears() => [for (var y = 2020; y <= 2050; y++) y.toDouble()];

List<double> quantumRaceCurve(List<double> years) {
  return years.map((y) => 1.0 / (1.0 + exp(-0.25 * (y - 2038)))).toList();
}

List<double> migrationEarlyCurve(List<double> years) {
  return years.map((y) => 1.0 / (1.0 + exp(-0.35 * (y - 2032)))).toList();
}

List<double> migrationLateCurve(List<double> years) {
  return years.map((y) => 1.0 / (1.0 + exp(-0.25 * (y - 2040)))).toList();
}

double log10(double x) => log(x) / log(10);

/// Milestone (year, qubit count) → FlSpot for log-scale chart.
List<(double year, double log10q)> quantumMilestonePoints() {
  const data = <(int, double)>[
    (2019, 53),
    (2021, 127),
    (2022, 433),
    (2023, 1121),
  ];
  return [
    for (final e in data) (e.$1.toDouble(), log10(e.$2)),
  ];
}

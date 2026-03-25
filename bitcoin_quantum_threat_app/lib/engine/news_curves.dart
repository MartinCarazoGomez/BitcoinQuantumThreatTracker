import 'dart:math';

/// Documented hardware milestones (same points as Streamlit `app.py` Plotly chart).
const List<({int year, int qubits, String chip, String org})> kQuantumMilestones = [
  (year: 2019, qubits: 53, chip: 'Sycamore', org: 'Google'),
  (year: 2021, qubits: 127, chip: 'Eagle', org: 'IBM'),
  (year: 2022, qubits: 433, chip: 'Osprey', org: 'IBM'),
  (year: 2023, qubits: 1121, chip: 'Condor', org: 'IBM'),
];

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

/// Milestone (year, qubit count) → FlSpot for log₁₀ qubits chart.
List<(double year, double log10q)> quantumMilestonePoints() {
  return [
    for (final m in kQuantumMilestones) (m.year.toDouble(), log10(m.qubits.toDouble())),
  ];
}

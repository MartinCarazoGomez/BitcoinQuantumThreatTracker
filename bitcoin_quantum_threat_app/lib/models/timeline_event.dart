class TimelineEvent {
  const TimelineEvent(this.year, this.title, this.type, this.detail);

  final int year;
  final String title;
  /// quantum | crypto | bitcoin | model
  final String type;
  final String detail;
}

/// Same rows as Streamlit `render_timeline` / `app.py`.
final List<TimelineEvent> kTimelineEvents = [
  const TimelineEvent(2019, 'Google quantum supremacy (Sycamore)', 'quantum', '~53-qubit processor; Nature, 23 Oct 2019'),
  const TimelineEvent(2021, 'IBM Eagle processor', 'quantum', '127-qubit chip publicly announced'),
  const TimelineEvent(2021, 'Bitcoin Taproot activation', 'bitcoin', 'Soft fork at block 709,632 (Nov 2021)'),
  const TimelineEvent(2022, 'NIST PQC algorithm selection', 'crypto', 'Kyber, Dilithium, SPHINCS+ chosen (July 2022)'),
  const TimelineEvent(2022, 'IBM Osprey processor', 'quantum', '433-qubit processor announced (Nov 2022)'),
  const TimelineEvent(2023, 'IBM Condor / System Two', 'quantum', '1121-qubit processor announced (Dec 2023)'),
  const TimelineEvent(2024, 'NIST FIPS post-quantum standards', 'crypto', 'FIPS 203, 204, 205; Aug 2024'),
  const TimelineEvent(2026, 'Simulator horizon start', 'model', 'Model window start—not a forecast.'),
  const TimelineEvent(2030, 'NIST / NSA RSA & ECDSA transition window', 'crypto', 'Policy milestone: move off RSA/ECDSA toward PQC.'),
  const TimelineEvent(2033, 'IBM roadmap: 2,000+ logical qubits', 'quantum', 'IBM public roadmap target.'),
  const TimelineEvent(2035, 'Legacy public-key cutoff (indicative)', 'crypto', 'Broader deprecation timelines vary by jurisdiction.'),
];

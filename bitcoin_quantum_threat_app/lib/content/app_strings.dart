// Copy aligned with Streamlit `app.py` where applicable.

class AppStrings {
  static const whyMatters =
      'Bitcoin uses ECDSA (and Schnorr) signatures tied to your private keys—quantum computers could eventually break that public-key math. '
      'Migration is a timing and coordination problem. This app models scenarios—not forecasts.';

  static const workflowSteps = <String>[
    'Context — Quick Check, News, or Timeline.',
    'Model — Simulator (Moderate preset, then sliders).',
    'Check — Compare & sensitivity; note critical years.',
    'Export — CSV from Summary.',
  ];

  static const chartGuideBullets = <String>[
    'Quantum — Capability to break ECDSA (0–1).',
    'Migration — Ecosystem PQ adoption (0–1).',
    'Risk — Mismatch when quantum runs ahead of migration.',
    'Crisis line — Threshold for “critical” year.',
  ];

  static const strategyNotes = <String, String>{
    'SPHINCS+': 'Strong security, larger signatures.',
    'Lamport': 'Simple, key management friction.',
    'Hybrid': 'Current + PQ, smoother migration.',
  };
}

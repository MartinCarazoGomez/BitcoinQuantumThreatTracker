// Copy aligned with Streamlit `app.py` where applicable.

class AppStrings {
  static const homeMeta = [
    ('Interactive', 'charts & sensitivity'),
    ('Explainable', 'deadlines & verdicts'),
    ('Presentation-ready', 'exports'),
  ];

  static const whyMatters =
      'Quantum computers could eventually threaten elliptic-curve signatures used widely today—including in Bitcoin. '
      'Post-quantum migration is a coordination and timing problem: this toolkit helps teams visualize mismatch risk, '
      'communicate trade-offs, and document assumptions for stakeholders—without claiming deterministic prediction.';

  static const workflowSteps = <String>[
    'Orient — Quick Check or News / Timeline for context.',
    'Model — Risk Simulator on Moderate preset, then tune sliders.',
    'Validate — Compare scenarios and Sensitivity tab; note any critical year.',
    'Share — Export CSV for slides or documentation.',
  ];

  static const chartGuideBullets = <String>[
    'Quantum capability — How close quantum computers are to breaking Bitcoin ECDSA signatures (0 = no threat, 1 = full capability).',
    'Migration progress — Share of the ecosystem that has moved to post-quantum cryptography.',
    'Risk curve — Mismatch risk: high when quantum is ahead of migration.',
    'Crisis threshold — Your risk limit; crossing it triggers a critical deadline.',
  ];

  static const strategyNotes = <String, String>{
    'SPHINCS+': 'Strong security, larger signatures.',
    'Lamport': 'Simple, key management friction.',
    'Hybrid': 'Current + PQ, smoother migration.',
  };
}

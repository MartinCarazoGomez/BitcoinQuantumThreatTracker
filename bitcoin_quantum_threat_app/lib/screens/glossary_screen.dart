import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  static const _terms = <(String, String)>[
    (
      'ECDSA',
      'Elliptic Curve Digital Signature Algorithm. Used by Bitcoin today. Vulnerable to sufficiently powerful quantum computers.',
    ),
    (
      'Post-quantum cryptography',
      'Cryptography designed to resist attacks from both classical and quantum computers.',
    ),
    (
      'Shor\'s algorithm',
      'Quantum algorithm that could break widely used public-key schemes (including the math behind ECDSA) on a large enough, fault-tolerant machine. Drives much of the PQC timeline discussion.',
    ),
    (
      'Grover\'s algorithm',
      'Quantum search that roughly halves the effective bit-strength of symmetric crypto and hashes (e.g. 256-bit targets feel like ~128-bit against a capable attacker). Relevant for address reuse and preimage work, but not a direct ECDSA break like Shor.',
    ),
    (
      'Physical vs logical qubits',
      'Physical qubits are noisy hardware elements; logical qubits bundle many physical ones with error correction. Cryptographically meaningful breaks usually assume large numbers of logical (fault-tolerant) qubits, not raw chip counts alone.',
    ),
    (
      'Fault-tolerant quantum computing',
      'Regime where errors are corrected fast enough that long, deep circuits (like cryptanalysis) can run reliably. Often assumed in “break ECDSA” scenarios.',
    ),
    (
      'ML-KEM / ML-DSA / SLH-DSA',
      'NIST-standardized post-quantum schemes (from Kyber/Dilithium/SPHINCS+ families). ML-KEM is key encapsulation; ML-DSA and SLH-DSA are signatures—relevant as reference designs for future non-Bitcoin systems and hybrid ideas.',
    ),
    (
      'SPHINCS+',
      'Stateless hash-based signature scheme. Conservative post-quantum option; larger signatures.',
    ),
    (
      'Lamport signatures',
      'One-time hash-based signatures. Simple but require new keys per signing.',
    ),
    (
      'Hybrid schemes',
      'Combine classical and post-quantum algorithms. Gradual migration path.',
    ),
    (
      'Harvest now, decrypt later',
      'Recording encrypted data or public keys today to break or abuse them when future quantum (or classical) attacks become feasible. Motivates early PQC adoption outside Bitcoin too.',
    ),
    (
      'UTXO',
      'Unspent Transaction Output. Bitcoin’s model: coins live in outputs locked by scripts and keys; migration discussions often revolve around how each UTXO type would move to new schemes.',
    ),
    (
      'Taproot / Schnorr',
      'Bitcoin’s modern script and signature tooling (BIP 340 Schnorr, Taproot spending paths). Still classical curves—quantum threat models still apply; any PQ upgrade would need a new design layer.',
    ),
    (
      'BIP-360',
      'Proposed Bitcoin improvement: Pay-to-Merkle-Root (P2MR) as a new address/spend path. Aims to keep public keys hidden behind a Merkle commitment until spend—reducing harvest-now exposure—and to accommodate larger post-quantum signatures via a soft-fork path. Status and timing follow community review (see resources).',
    ),
    (
      'Pay-to-Merkle Root (P2MR)',
      'Address pattern paired with BIP-360: the locking condition references a Merkle root instead of revealing the full public key up front, limiting on-chain key exposure compared with traditional spends. Often discussed together with hash-based signatures such as SPHINCS+ (SLH-DSA).',
    ),
    (
      'Soft fork vs hard fork',
      'Soft fork: tightened rules, old nodes still see blocks as valid if they follow old rules. Hard fork: incompatible rule change. Post-quantum Bitcoin changes are often debated in terms of coordination and backward compatibility.',
    ),
    (
      'Quantum break year',
      'Year when this model’s quantum-capability curve reaches 50% (logistic midpoint). Scenario presets follow FNCE313 Q-Day bands: Optimistic 2040+, Moderate 2033+, Pessimistic 2029–2031 (2030 midpoint).',
    ),
    (
      'Migration 50%',
      'Year when ~50% of Bitcoin value/users are estimated to have migrated to post-quantum.',
    ),
  ];

  static const _links = <(String, String)>[
    ('NIST PQC Project', 'https://csrc.nist.gov/projects/post-quantum-cryptography'),
    ('NIST PQC Standardization', 'https://csrc.nist.gov/projects/post-quantum-cryptography/post-quantum-cryptography-standardization'),
    ('Bitcoin BIPs', 'https://github.com/bitcoin/bips'),
    ('Bitcoin Optech', 'https://bitcoinops.org/'),
    ('Bitcoin Wiki — Quantum computing', 'https://en.bitcoin.it/wiki/Quantum_computing_and_Bitcoin'),
    ('BIP-360 / P2MR', 'https://bip360.org/'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glossary & Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final t in _terms)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(t.$2, style: const TextStyle(color: AppColors.muted, height: 1.45)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Text('Resources', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          for (final l in _links)
            ListTile(
              title: Text(l.$1, style: const TextStyle(color: AppColors.amber)),
              trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.muted),
              onTap: () => launchUrl(Uri.parse(l.$2), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}

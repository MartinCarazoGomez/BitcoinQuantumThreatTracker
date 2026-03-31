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
      'Quantum algorithm that breaks common public-key math (including ECDSA) on a large enough fault-tolerant machine.',
    ),
    (
      'Grover\'s algorithm',
      'Quantum search; roughly halves symmetric/hash strength. Not an ECDSA break like Shor.',
    ),
    (
      'Physical vs logical qubits',
      'Physical = noisy hardware. Logical = error-corrected; serious break estimates use logical qubits.',
    ),
    (
      'Fault-tolerant quantum computing',
      'Error-corrected regime where deep circuits (e.g. cryptanalysis) can run reliably.',
    ),
    (
      'ML-KEM / ML-DSA / SLH-DSA',
      'NIST PQ standards (from Kyber/Dilithium/SPHINCS+ families). KEM and signature roles differ.',
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
      'Store ciphertext or keys now; decrypt when hardware allows.',
    ),
    (
      'UTXO',
      'Unspent transaction output—Bitcoin’s coin model.',
    ),
    (
      'Taproot / Schnorr',
      'BIP 340 Schnorr and Taproot paths. Still classical; PQ needs new layers.',
    ),
    (
      'BIP-360',
      'Proposal for Pay-to-Merkle-Root spends: hide keys behind a Merkle root; soft-fork path for larger PQ sigs.',
    ),
    (
      'Pay-to-Merkle Root (P2MR)',
      'Lock to a Merkle root instead of exposing the full pubkey up front.',
    ),
    (
      'Soft fork vs hard fork',
      'Soft fork: tighter rules, backward compatible. Hard fork: incompatible change.',
    ),
    (
      'Quantum break year',
      'Model year where quantum capability hits 50% on the logistic curve. Presets: Optimistic 2040+, Moderate 2033+, Pessimistic ~2030.',
    ),
    (
      'Migration 50%',
      'Model year when migration curve hits 50%.',
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

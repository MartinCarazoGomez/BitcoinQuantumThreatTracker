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
      'Quantum break year',
      'Year when quantum computers are estimated to reach ~50% capability to break current crypto.',
    ),
    (
      'Migration 50%',
      'Year when ~50% of Bitcoin value/users are estimated to have migrated to post-quantum.',
    ),
  ];

  static const _links = <(String, String)>[
    ('NIST PQC Project', 'https://csrc.nist.gov/projects/post-quantum-cryptography'),
    ('Bitcoin BIPs', 'https://github.com/bitcoin/bips'),
    ('Bitcoin Optech', 'https://bitcoinops.org/'),
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

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Landing hub — mirrors Streamlit home CTAs.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenSimulator, required this.onOpenQuick});

  final VoidCallback onOpenSimulator;
  final VoidCallback onOpenQuick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface2.withValues(alpha: 0.9),
                AppColors.bg,
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
                  color: AppColors.amber.withValues(alpha: 0.1),
                ),
                child: const Text(
                  'DECISION INTELLIGENCE · SCENARIO MODELING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFfef3c7), AppColors.amber, AppColors.amberLight],
                ).createShader(bounds),
                child: const Text(
                  'Bitcoin Quantum\nThreat Toolkit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'See how quantum progress and post-quantum migration can drift out of sync—then stress-test assumptions with charts and exports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.95),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'START HERE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        _CtaCard(
          title: 'Quick Risk Check',
          subtitle: 'Four questions → instant risk band.',
          primary: true,
          onTap: onOpenQuick,
        ),
        const SizedBox(height: 10),
        _CtaCard(
          title: 'Risk Simulator',
          subtitle: 'Sliders, charts, compare scenarios, CSV export.',
          primary: false,
          onTap: onOpenSimulator,
        ),
        const SizedBox(height: 20),
        Text(
          'Use the bottom navigation to open Simulator, Quick Check, News, Glossary, or Timeline.',
          style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 13, height: 1.45),
        ),
      ],
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary
                  ? AppColors.amber.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            gradient: primary
                ? LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.12),
                      AppColors.surface.withValues(alpha: 0.5),
                    ],
                  )
                : null,
            color: primary ? null : AppColors.surface.withValues(alpha: 0.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

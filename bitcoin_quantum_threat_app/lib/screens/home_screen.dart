import 'package:flutter/material.dart';

import '../content/app_strings.dart';
import '../theme/app_theme.dart';

/// Landing hub — mirrors Streamlit `render_home()`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenSimulator, required this.onOpenQuick});

  final VoidCallback onOpenSimulator;
  final VoidCallback onOpenQuick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
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
                'See how quantum progress and post-quantum migration can drift out of sync—then stress-test '
                'assumptions with charts, comparisons, and exports. Models illustrate scenarios, not predictions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.95),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < AppStrings.homeMeta.length; i++) ...[
                    if (i > 0)
                      Text('·', style: TextStyle(color: AppColors.muted.withValues(alpha: 0.5))),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: AppStrings.homeMeta[i].$1,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                          ),
                          TextSpan(
                            text: ' ${AppStrings.homeMeta[i].$2}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'START HERE — PICK ONE PATH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 12),
        _CtaCard(
          kicker: 'Fast · Low friction',
          title: 'Quick Risk Check',
          subtitle:
              'Four multiple-choice questions → an instant risk band. Best for a first read or a stakeholder snapshot.',
          primary: true,
          onTap: onOpenQuick,
        ),
        const SizedBox(height: 10),
        _CtaCard(
          kicker: 'Deep dive',
          title: 'Risk Simulator',
          subtitle: 'Sliders, three scenario presets, charts, compare runs, sensitivity sweeps, and CSV export.',
          primary: false,
          onTap: onOpenSimulator,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _StatTile(value: '3', label: 'Scenario presets')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: '30yr', label: 'Horizon (2026–2055)')),
            const SizedBox(width: 10),
            Expanded(child: _StatTile(value: '6', label: 'Tabs (see bar below)')),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'NAVIGATION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Use the bottom bar to switch between Home, Simulator, Quick Check, News, Glossary, and Timeline.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted.withValues(alpha: 0.92), fontSize: 13, height: 1.55),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface.withValues(alpha: 0.35),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.2), style: BorderStyle.solid),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUGGESTED WORKFLOW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(AppStrings.workflowSteps.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${i + 1}. ${AppStrings.workflowSteps[i]}',
                    style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.5, fontSize: 13),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface.withValues(alpha: 0.4),
            border: Border(
              left: BorderSide(color: AppColors.amber.withValues(alpha: 0.85), width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why this matters',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.whyMatters,
                style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.55, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.amber)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 0.06, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  const _CtaCard({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.onTap,
  });

  final String kicker;
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
                kicker.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: primary ? AppColors.amberLight : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
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

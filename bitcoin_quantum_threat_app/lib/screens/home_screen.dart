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
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        const SizedBox(height: 4),
        Text(
          'Bitcoin Quantum\nThreat Toolkit',
          style: t.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppColors.text,
                letterSpacing: -0.5,
              ) ??
              const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.15,
                color: AppColors.text,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stress-test quantum vs migration timing with charts and export.',
          style: t.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ) ??
              TextStyle(
                fontSize: 15,
                color: AppColors.muted.withValues(alpha: 0.95),
                height: 1.45,
              ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in AppStrings.homeMeta)
              _MetaChip(label: m.$1, detail: m.$2),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Get started',
          style: t.titleSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        _HomeActionCard(
          icon: Icons.bolt_rounded,
          iconColor: AppColors.amber,
          title: 'Quick Risk Check',
          subtitle: 'Four questions → a risk band.',
          emphasized: true,
          onTap: onOpenQuick,
        ),
        const SizedBox(height: 10),
        _HomeActionCard(
          icon: Icons.area_chart_rounded,
          iconColor: AppColors.quantum,
          title: 'Risk Simulator',
          subtitle: 'Sliders, compare, sensitivity, CSV.',
          emphasized: false,
          onTap: onOpenSimulator,
        ),
        const SizedBox(height: 28),
        Text(
          'At a glance',
          style: t.titleSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _GlanceStat(value: '3', caption: 'Scenario presets', icon: Icons.layers_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _GlanceStat(value: '30 yr', caption: 'Horizon to 2055', icon: Icons.date_range_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _GlanceStat(value: '6', caption: 'Sections in app', icon: Icons.apps_outlined)),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.route_outlined, size: 20, color: AppColors.amber.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested workflow',
                      style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...List.generate(AppStrings.workflowSteps.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == AppStrings.workflowSteps.length - 1 ? 0 : 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface2.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.workflowSteps[i],
                            style: TextStyle(
                              color: AppColors.muted.withValues(alpha: 0.98),
                              height: 1.45,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.surface.withValues(alpha: 0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.amber.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppColors.amberLight.withValues(alpha: 0.95)),
                    const SizedBox(width: 8),
                    Text(
                      'Why this matters',
                      style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.whyMatters,
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.96),
                    height: 1.55,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface2.withValues(alpha: 0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.swipe_vertical_outlined, size: 18, color: AppColors.muted.withValues(alpha: 0.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Other sections: bottom navigation.',
                    style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface2.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, height: 1.25),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
            ),
            TextSpan(
              text: ' · $detail',
              style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emphasized ? AppColors.amber.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.1),
              width: emphasized ? 1.2 : 1,
            ),
            color: emphasized ? AppColors.amber.withValues(alpha: 0.1) : AppColors.surface.withValues(alpha: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: (emphasized ? AppColors.amber : iconColor).withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted.withValues(alpha: 0.95),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted.withValues(alpha: 0.65),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlanceStat extends StatelessWidget {
  const _GlanceStat({required this.value, required this.caption, required this.icon});

  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface.withValues(alpha: 0.65),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.muted.withValues(alpha: 0.85)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.amber),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.muted.withValues(alpha: 0.92),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

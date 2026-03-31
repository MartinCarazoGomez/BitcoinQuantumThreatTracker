import 'dart:math' show max, min;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../content/app_strings.dart';
import '../engine/btc_price.dart';
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
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              'Bitcoin Quantum Threat Toolkit',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ) ??
                  const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.text,
                  ),
            ),
          ),
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
        Text(
          'Market context',
          style: t.titleSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        const _BtcYearPriceCard(),
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
      ],
    );
  }
}

class _BtcYearPriceCard extends StatefulWidget {
  const _BtcYearPriceCard();

  @override
  State<_BtcYearPriceCard> createState() => _BtcYearPriceCardState();
}

class _BtcYearPriceCardState extends State<_BtcYearPriceCard> {
  late Future<List<BtcPricePoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchBtcUsdHistory(days: 365);
  }

  static String _fmtUsd(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.amber.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: FutureBuilder<List<BtcPricePoint>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Could not load BTC price (network or API). ${snap.error}',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), fontSize: 13, height: 1.4),
                ),
              );
            }
            final points = snap.data!;
            if (points.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No price data.', style: TextStyle(color: AppColors.muted)),
              );
            }
            final ys = points.map((e) => e.usd).toList();
            var lo = ys.reduce(min);
            var hi = ys.reduce(max);
            final pad = (hi - lo) * 0.06;
            if (pad < 1) {
              lo -= 1;
              hi += 1;
            } else {
              lo -= pad;
              hi += pad;
            }
            final spots = <FlSpot>[
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].usd),
            ];
            final n = points.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.currency_bitcoin, size: 20, color: AppColors.amber.withValues(alpha: 0.95)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'BTC/USDT — last 12 months (1d)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily close · UTC (Binance, else CoinGecko / CryptoCompare)',
                  style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.88)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (n - 1).toDouble(),
                      minY: lo,
                      maxY: hi,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (hi - lo) > 0 ? (hi - lo) / 4 : 1,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.muted.withValues(alpha: 0.12),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            interval: (hi - lo) > 0 ? (hi - lo) / 4 : null,
                            getTitlesWidget: (v, meta) {
                              return Text(
                                _fmtUsd(v),
                                style: const TextStyle(fontSize: 9, color: AppColors.muted),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              final i = v.round().clamp(0, n - 1);
                              final mid = (n - 1) ~/ 2;
                              final show = i == 0 || i == n - 1 || i == mid;
                              if (!show) return const SizedBox.shrink();
                              final d = points[i].time.toUtc();
                              final label = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          color: AppColors.amber,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.amber.withValues(alpha: 0.2),
                                AppColors.amber.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return List<LineTooltipItem?>.generate(touchedSpots.length, (j) {
                              final t = touchedSpots[j];
                              final xi = t.x.round().clamp(0, n - 1);
                              final date = points[xi].time.toUtc().toString().split(' ').first;
                              return LineTooltipItem(
                                '$date\n${_fmtUsd(t.y)}',
                                const TextStyle(color: Colors.white, fontSize: 11, height: 1.25),
                              );
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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

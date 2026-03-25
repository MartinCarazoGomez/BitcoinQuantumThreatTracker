import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';

import '../engine/news_curves.dart';
import '../theme/app_theme.dart';

const _kOverviewIbmQuantum = 'assets/images/overview_ibm_quantum.jpg';
const _kOverviewNist = 'assets/images/overview_nist.jpg';
const _kOverviewBitcoin = 'assets/images/overview_bitcoin.png';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<_NewsBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFeeds();
  }

  Future<_NewsBundle> _loadFeeds() async {
    final feeds = <String, List<_NewsItem>>{};
    final errors = <String, String?>{};
    const urls = [
      ('https://cointelegraph.com/rss', 'Crypto & Blockchain'),
      ('https://bitcoinmagazine.com/.feed', 'Bitcoin'),
    ];
    for (final u in urls) {
      errors[u.$2] = null;
      try {
        final res = await http.get(
          Uri.parse(u.$1),
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; BQTT/1.0)'},
        );
        if (res.statusCode != 200) {
          feeds[u.$2] = [];
          errors[u.$2] = 'HTTP ${res.statusCode}';
          continue;
        }
        final rss = RssFeed.parse(res.body);
        final items = <_NewsItem>[];
        for (final item in rss.items ?? []) {
          if (items.length >= 4) break;
          final desc = item.description ?? '';
          final link = item.link?.trim() ?? '';
          items.add(_NewsItem(
            title: item.title ?? '',
            summary: _stripHtml(desc),
            pub: item.pubDate?.toIso8601String().substring(0, 10) ?? '',
            link: link.isNotEmpty ? link : null,
          ));
        }
        feeds[u.$2] = items;
      } catch (e) {
        feeds[u.$2] = [];
        errors[u.$2] = e.toString();
      }
    }
    return _NewsBundle(feeds, errors);
  }

  static String _stripHtml(String s) {
    var t = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 400) t = '${t.substring(0, 397)}...';
    return t;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Widget _overviewImage(String assetPath, String caption) {
    return _NewsOverviewImage(assetPath: assetPath, caption: caption);
  }

  Widget _overviewRow({required Widget image, required Widget text, required bool narrow}) {
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          image,
          const SizedBox(height: 10),
          text,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: image),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: text),
      ],
    );
  }

  Widget _overviewBlock(double maxWidth) {
    final narrow = maxWidth < 520;
    final body = TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.5, fontSize: 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 14),
        _overviewRow(
          narrow: narrow,
          image: _overviewImage(_kOverviewIbmQuantum, 'IBM Quantum System One'),
          text: Text.rich(
            TextSpan(
              style: body,
              children: const [
                TextSpan(text: 'Quantum computing', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                TextSpan(text: ' — Progress is accelerating. Google\'s 2019 Sycamore demonstration showed '
                    'quantum supremacy (53 qubits). IBM, IonQ, and others are scaling qubit counts into the hundreds. '
                    'Current estimates suggest large-scale fault-tolerant machines capable of breaking ECDSA and RSA '
                    'could arrive in the 2030s–2040s, though timelines are uncertain.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _overviewRow(
          narrow: narrow,
          image: _overviewImage(_kOverviewNist, 'NIST (main gate)'),
          text: Text.rich(
            TextSpan(
              style: body,
              children: [
                const TextSpan(text: 'NIST post-quantum cryptography', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                const TextSpan(text: ' — In '),
                const TextSpan(text: 'July 2022', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.amber)),
                const TextSpan(
                  text: ', NIST selected algorithms for standardization '
                      '(including CRYSTALS-Kyber and CRYSTALS-Dilithium, later ML-KEM / ML-DSA, and SPHINCS+-related SLH-DSA). '
                      'In ',
                ),
                const TextSpan(text: 'August 2024', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.amber)),
                const TextSpan(
                  text: ', NIST published ',
                ),
                const TextSpan(text: 'FIPS 203, 204, and 205', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                const TextSpan(text: ' (ML-KEM, ML-DSA, SLH-DSA). Adoption in TLS and other systems is ongoing.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _overviewRow(
          narrow: narrow,
          image: _overviewImage(_kOverviewBitcoin, 'Bitcoin'),
          text: Text.rich(
            TextSpan(
              style: body,
              children: const [
                TextSpan(text: 'Bitcoin', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                TextSpan(
                  text: ' — There is no network-wide post-quantum migration yet. Developers and researchers discuss '
                      'post-quantum signatures and soft-fork trade-offs in public forums (e.g. Bitcoin dev mailing list, '
                      'Bitcoin Optech newsletter). Hybrid schemes (ECDSA plus a post-quantum component) are often discussed; '
                      'coordination would be required across the ecosystem.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _milestoneColors = [AppColors.quantum, AppColors.migration, Color(0xFF22d3ee), AppColors.accent];

  Widget _milestoneChart() {
    final pts = quantumMilestonePoints();
    final spots = [for (var i = 0; i < pts.length; i++) FlSpot(pts[i].$1, pts[i].$2)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantum computing progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'Key quantum computing milestones (log₁₀ of physical qubit count)',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: 2018,
              maxX: 2024,
              minY: 1,
              maxY: 3.5,
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'log₁₀(qubits)',
                    style: TextStyle(fontSize: 9, color: AppColors.muted.withValues(alpha: 0.85)),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text('Year', style: TextStyle(fontSize: 9, color: AppColors.muted.withValues(alpha: 0.85))),
                  axisNameSize: 14,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              lineBarsData: [
                for (var i = 0; i < spots.length; i++)
                  LineChartBarData(
                    spots: [spots[i]],
                    color: _milestoneColors[i % _milestoneColors.length],
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s0, s1, i2, c) => FlDotCirclePainter(
                        radius: 10,
                        color: _milestoneColors[i % _milestoneColors.length],
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) {
                    final out = <LineTooltipItem>[];
                    for (final t in touched) {
                      final bar = t.barIndex.clamp(0, kQuantumMilestones.length - 1);
                      final m = kQuantumMilestones[bar];
                      out.add(LineTooltipItem(
                        '${m.chip} (${m.org})\n${m.qubits} qubits · log₁₀=${t.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontSize: 11, height: 1.25),
                      ));
                    }
                    return out;
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < kQuantumMilestones.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surface.withValues(alpha: 0.6),
                  border: Border.all(color: _milestoneColors[i].withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${kQuantumMilestones[i].chip} · ${kQuantumMilestones[i].qubits} qubits (${kQuantumMilestones[i].year})',
                  style: const TextStyle(fontSize: 11, color: AppColors.text),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Documented IBM/Google hardware announcements (physical qubit counts, not logical qubit counts). '
          'Breaking ECDSA in practice may require large-scale fault-tolerant machines—timing remains uncertain.',
          style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }

  Widget _raceChart() {
    final years = raceYears();
    final q = quantumRaceCurve(years);
    final me = migrationEarlyCurve(years);
    final ml = migrationLateCurve(years);
    final spotsQ = [for (var i = 0; i < years.length; i++) FlSpot(years[i], q[i])];
    final spotsE = [for (var i = 0; i < years.length; i++) FlSpot(years[i], me[i])];
    final spotsL = [for (var i = 0; i < years.length; i++) FlSpot(years[i], ml[i])];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The race: quantum threat vs migration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'Conceptual timeline: when quantum may outpace Bitcoin migration',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 2020,
              maxX: 2050,
              minY: 0,
              maxY: 1,
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 0.2,
                    getTitlesWidget: (v, m) {
                      final p = (v.clamp(0.0, 1.0) * 100).round();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text('$p%', style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text('Year', style: TextStyle(fontSize: 9, color: AppColors.muted.withValues(alpha: 0.85))),
                  axisNameSize: 14,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 5,
                    getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              lineBarsData: [
                LineChartBarData(spots: spotsQ, color: AppColors.quantum, barWidth: 2.5, isCurved: true, dotData: const FlDotData(show: false)),
                LineChartBarData(
                  spots: spotsE,
                  color: AppColors.migration,
                  barWidth: 2,
                  isCurved: true,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: spotsL,
                  color: AppColors.risk,
                  barWidth: 2,
                  isCurved: true,
                  dashArray: [2, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    if (spots.isEmpty) return [];
                    final y = spots.first.x.round();
                    const names = ['Quantum capability (est.)', 'Migration (early)', 'Migration (late)'];
                    return [
                      for (var i = 0; i < spots.length; i++)
                        LineTooltipItem(
                          'Year $y\n${names[spots[i].barIndex.clamp(0, 2)]}: ${(spots[i].y * 100).round()}%',
                          const TextStyle(color: Colors.white, fontSize: 11, height: 1.25),
                        ),
                    ];
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Early migration stays ahead of quantum; late migration risks a dangerous overlap.',
          style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 6),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendDot(color: AppColors.quantum, label: 'Quantum capability (est.)'),
            _LegendDot(color: AppColors.migration, label: 'Migration (early)'),
            _LegendDot(color: AppColors.risk, label: 'Migration (late)'),
          ],
        ),
      ],
    );
  }

  Widget _headlineCard(_NewsItem item) {
    final link = item.link;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: link != null ? () => _openUrl(link) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.25)),
                  ),
                  if (link != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.open_in_new, size: 16, color: AppColors.amber),
                    ),
                ],
              ),
              if (item.pub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.pub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
              if (item.summary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.amber.withValues(alpha: 0.45), width: 3)),
                    color: AppColors.surface.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.summary,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News & Updates')),
      body: FutureBuilder<_NewsBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.amber));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.risk)));
          }
          final bundle = snap.data!;
          return RefreshIndicator(
            color: AppColors.amber,
            onRefresh: () async {
              setState(() => _future = _loadFeeds());
              await _future;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.12)),
                        color: AppColors.surface.withValues(alpha: 0.45),
                      ),
                      child: Text(
                        'Current state of quantum computing, post-quantum cryptography, and Bitcoin migration.',
                        style: TextStyle(color: AppColors.muted.withValues(alpha: 0.98), height: 1.45, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _overviewBlock(constraints.maxWidth),
                    const SizedBox(height: 28),
                    _milestoneChart(),
                    const SizedBox(height: 28),
                    _raceChart(),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    const Text('Recent headlines & summaries', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh. RSS needs network; web builds may hit CORS in some browsers. Tap a headline to open the article when a link is available.',
                      style: TextStyle(color: AppColors.muted.withValues(alpha: 0.88), fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    for (final e in bundle.feeds.entries) ...[
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.amber)),
                      const SizedBox(height: 8),
                      if (bundle.errors[e.key] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Unable to load feed: ${bundle.errors[e.key]}',
                            style: const TextStyle(fontSize: 12, color: AppColors.risk, height: 1.35),
                          ),
                        )
                      else if (e.value.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('No items returned for this feed.', style: TextStyle(color: AppColors.muted)),
                        )
                      else
                        for (final item in e.value) _headlineCard(item),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewsOverviewImage extends StatelessWidget {
  const _NewsOverviewImage({required this.assetPath, required this.caption});
  final String assetPath;
  final String caption;

  static const _error = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.broken_image_outlined, color: AppColors.muted),
      SizedBox(height: 6),
      Text(
        'Image unavailable',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: AppColors.surface,
            child: Image.asset(
              assetPath,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 120,
                width: double.infinity,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: _error,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(caption, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
} 

class _NewsItem {
  _NewsItem({required this.title, required this.summary, required this.pub, this.link});
  final String title;
  final String summary;
  final String pub;
  final String? link;
}

class _NewsBundle {
  _NewsBundle(this.feeds, this.errors);
  final Map<String, List<_NewsItem>> feeds;
  final Map<String, String?> errors;
}

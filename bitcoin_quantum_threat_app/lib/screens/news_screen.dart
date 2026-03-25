import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

import '../engine/news_curves.dart';
import '../theme/app_theme.dart';

/// Wikimedia Commons (same URLs as Streamlit `app.py`).
const _kNewsImages = <String, String>{
  'quantum':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/IBM_Quantum_System_One.jpg/640px-IBM_Quantum_System_One.jpg',
  'nist': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/NIST_Campus_Main_Gate.jpg/640px-NIST_Campus_Main_Gate.jpg',
  'bitcoin':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/512px-Bitcoin.svg.png',
};

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
    const urls = [
      ('https://cointelegraph.com/rss', 'Crypto & Blockchain'),
      ('https://bitcoinmagazine.com/.feed', 'Bitcoin'),
    ];
    for (final u in urls) {
      try {
        final res = await http.get(
          Uri.parse(u.$1),
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; BQTT/1.0)'},
        );
        if (res.statusCode != 200) continue;
        final rss = RssFeed.parse(res.body);
        final items = <_NewsItem>[];
        for (final item in rss.items ?? []) {
          if (items.length >= 4) break;
          final desc = item.description ?? '';
          items.add(_NewsItem(
            title: item.title ?? '',
            summary: _stripHtml(desc),
            pub: item.pubDate?.toIso8601String().substring(0, 10) ?? '',
          ));
        }
        feeds[u.$2] = items;
      } catch (_) {
        feeds[u.$2] = [];
      }
    }
    return _NewsBundle(feeds);
  }

  static String _stripHtml(String s) {
    var t = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length > 400) t = '${t.substring(0, 397)}...';
    return t;
  }

  Widget _netImage(String url, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              color: AppColors.surface,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(caption, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }

  Widget _overviewBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _netImage(_kNewsImages['quantum']!, 'IBM Quantum System One')),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                'Quantum computing — Progress is accelerating. Google\'s 2019 Sycamore demonstration showed '
                'quantum supremacy (53 qubits). IBM, IonQ, and others are scaling qubit counts into the hundreds. '
                'Current estimates suggest large-scale fault-tolerant machines capable of breaking ECDSA and RSA '
                'could arrive in the 2030s–2040s, though timelines are uncertain.',
                style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.45, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _netImage(_kNewsImages['nist']!, 'NIST campus')),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                'NIST post-quantum cryptography — In July 2022, NIST selected algorithms for standardization '
                '(including CRYSTALS-Kyber and CRYSTALS-Dilithium, later ML-KEM / ML-DSA, and SPHINCS+-related SLH-DSA). '
                'In August 2024, NIST published FIPS 203, 204, and 205 (ML-KEM, ML-DSA, SLH-DSA). '
                'Adoption in TLS and other systems is ongoing.',
                style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.45, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _netImage(_kNewsImages['bitcoin']!, 'Bitcoin')),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                'Bitcoin — There is no network-wide post-quantum migration yet. Developers and researchers discuss '
                'post-quantum signatures and soft-fork trade-offs in public forums (e.g. Bitcoin dev mailing list, '
                'Bitcoin Optech newsletter). Hybrid schemes (ECDSA plus a post-quantum component) are often discussed; '
                'coordination would be required across the ecosystem.',
                style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.45, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _milestoneChart() {
    final pts = quantumMilestonePoints();
    final spots = [
      FlSpot(pts[0].$1, pts[0].$2),
      FlSpot(pts[1].$1, pts[1].$2),
      FlSpot(pts[2].$1, pts[2].$2),
      FlSpot(pts[3].$1, pts[3].$2),
    ];
    const colors = [AppColors.quantum, AppColors.migration, Color(0xFF22d3ee), AppColors.accent];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantum computing progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        const Text(
          'Key quantum computing milestones (log₁₀ qubits)',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 2018,
              maxX: 2024,
              minY: 1,
              maxY: 3.5,
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ),
                ),
                bottomTitles: AxisTitles(
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
                    color: colors[i % colors.length],
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s0, s1, i2, c) => FlDotCirclePainter(
                        radius: 10,
                        color: colors[i % colors.length],
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) {
                    const labels = ['Sycamore', 'Eagle', 'Osprey', 'Condor'];
                    return [
                      for (var i = 0; i < touched.length; i++)
                        LineTooltipItem(
                          '${labels[touched[i].spotIndex.clamp(0, 3)]}\n${touched[i].y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
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
          'Documented IBM/Google hardware announcements (physical qubit counts, not logical qubit counts). '
          'Breaking ECDSA in practice may require large-scale fault-tolerant machines—timing remains uncertain.',
          style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
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
        const Text('The race: quantum threat vs migration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        const Text(
          'Conceptual timeline: when quantum may outpace Bitcoin migration',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: 2020,
              maxX: 2050,
              minY: 0,
              maxY: 1,
              gridData: FlGridData(show: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                bottomTitles: AxisTitles(
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
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Early migration stays ahead of quantum; late migration risks a dangerous overlap.',
          style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 4),
        const Wrap(
          spacing: 12,
          children: [
            _LegendDot(color: AppColors.quantum, label: 'Quantum (est.)'),
            _LegendDot(color: AppColors.migration, label: 'Migration (early)'),
            _LegendDot(color: AppColors.risk, label: 'Migration (late)'),
          ],
        ),
      ],
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Current state of quantum computing, post-quantum cryptography, and Bitcoin migration.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 20),
                _overviewBlock(),
                const SizedBox(height: 28),
                _milestoneChart(),
                const SizedBox(height: 28),
                _raceChart(),
                const SizedBox(height: 28),
                const Text('Recent headlines & summaries', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'RSS (needs network). Web builds may hit CORS in some browsers.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.85), fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (final e in bundle.feeds.entries) ...[
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (e.value.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('Unable to load this feed.', style: TextStyle(color: AppColors.muted)),
                    )
                  else
                    for (final item in e.value)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (item.pub.isNotEmpty)
                                Text(item.pub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                              if (item.summary.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.summary,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _NewsItem {
  _NewsItem({required this.title, required this.summary, required this.pub});
  final String title;
  final String summary;
  final String pub;
}

class _NewsBundle {
  _NewsBundle(this.feeds);
  final Map<String, List<_NewsItem>> feeds;
}

import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';

import '../content/news_visual_context.dart';
import '../engine/news_curves.dart';
import '../theme/app_theme.dart';

/// [Polymarket](https://polymarket.com/event/will-bitcoin-replace-sha-256-before-2027) event; odds from Gamma API.
const _kPolymarketEventUrl = 'https://polymarket.com/event/will-bitcoin-replace-sha-256-before-2027';
const _kPolymarketGammaUrl = 'https://gamma-api.polymarket.com/events?slug=will-bitcoin-replace-sha-256-before-2027';

const _kHttpJsonHeaders = {
  'User-Agent': 'BitcoinQuantumThreatToolkit/1.0 (Flutter; educational)',
  'Accept': 'application/json',
};

const _kPolymarketSnapshotAsset = 'assets/data/polymarket_snapshot.json';

/// Flutter web serves `pubspec` assets at `<base>assets/<pubspecAssetPath>` (note the extra `assets/` segment).
Uri _flutterWebBundledAssetUri(String pubspecAssetPath, {required bool cacheBust}) {
  final b = Uri.base;
  var basePath = b.path.isEmpty ? '/' : b.path;
  if (!basePath.endsWith('/')) {
    final i = basePath.lastIndexOf('/');
    basePath = i >= 0 ? basePath.substring(0, i + 1) : '/';
  }
  final path = '${basePath}assets/$pubspecAssetPath';
  return Uri(
    scheme: b.scheme,
    host: b.host,
    port: b.hasPort ? b.port : null,
    path: path,
    queryParameters: cacheBust ? {'v': DateTime.now().millisecondsSinceEpoch.toString()} : null,
  );
}

({_PolymarketSnapshot? snap, String? err}) _parsePolymarketEventsBody(String body, {required bool fromWebSnapshot}) {
  try {
    final list = jsonDecode(body);
    if (list is! List || list.isEmpty) {
      return (snap: null, err: 'No market data returned');
    }
    final event = list.first;
    if (event is! Map<String, dynamic>) {
      return (snap: null, err: 'Unexpected API shape');
    }
    final markets = event['markets'];
    if (markets is! List || markets.isEmpty) {
      return (snap: null, err: 'Market listing empty');
    }
    final m = markets.first;
    if (m is! Map<String, dynamic>) {
      return (snap: null, err: 'Unexpected market shape');
    }
    final question = m['question'] as String? ?? 'Will Bitcoin replace SHA-256 before 2027?';
    final outcomesRaw = m['outcomes'];
    final pricesRaw = m['outcomePrices'];
    final outcomes = outcomesRaw is String
        ? jsonDecode(outcomesRaw) as List<dynamic>
        : outcomesRaw is List
            ? outcomesRaw
            : null;
    final prices = pricesRaw is String
        ? jsonDecode(pricesRaw) as List<dynamic>
        : pricesRaw is List
            ? pricesRaw
            : null;
    if (outcomes == null || prices == null || outcomes.length != prices.length) {
      return (snap: null, err: 'Could not parse outcomes/prices');
    }
    double? yesP;
    double? noP;
    for (var i = 0; i < outcomes.length; i++) {
      final label = outcomes[i].toString().toLowerCase().trim();
      final p = double.tryParse(prices[i].toString());
      if (p == null) continue;
      if (label == 'yes') yesP = p;
      if (label == 'no') noP = p;
    }
    yesP ??= double.tryParse(prices.first.toString());
    noP ??= (prices.length > 1) ? double.tryParse(prices[1].toString()) : null;
    if (yesP == null) {
      return (snap: null, err: 'Could not read implied odds');
    }
    yesP = yesP.clamp(0.0, 1.0);
    noP = (noP ?? (1.0 - yesP)).clamp(0.0, 1.0);
    final liq = (m['liquidityNum'] as num?)?.toDouble() ??
        double.tryParse(m['liquidity']?.toString() ?? '') ??
        (event['liquidity'] as num?)?.toDouble();
    final endLabel = (m['endDateIso'] as String?)?.trim();
    return (
      snap: _PolymarketSnapshot(
        question: question,
        yesProbability: yesP,
        noProbability: noP,
        endDateLabel: (endLabel != null && endLabel.isNotEmpty) ? endLabel : '2026-12-31',
        liquidityUsd: liq,
        fetchedAt: DateTime.now(),
        fromWebSnapshot: fromWebSnapshot,
      ),
      err: null
    );
  } catch (e) {
    return (snap: null, err: e.toString());
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<_NewsScreenData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadScreenData();
  }

  Future<_NewsScreenData> _loadScreenData() async {
    final feedFuture = _loadFeeds();
    final polyFuture = _fetchPolymarket();
    final bundle = await feedFuture;
    final poly = await polyFuture;
    return _NewsScreenData(
      bundle: bundle,
      polymarket: poly.snap,
      polymarketError: poly.err,
    );
  }

  Future<_NewsBundle> _loadFeeds() async {
    final feeds = <String, List<_NewsItem>>{};
    const urls = [
      ('https://cointelegraph.com/rss', 'Crypto & Blockchain'),
    ];
    for (final u in urls) {
      try {
        final res = await http.get(
          Uri.parse(u.$1),
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; BQTT/1.0)'},
        );
        if (res.statusCode != 200) {
          feeds[u.$2] = [];
          continue;
        }
        final rss = RssFeed.parse(_decodeRssResponseBody(res));
        final items = <_NewsItem>[];
        for (final item in rss.items ?? []) {
          if (items.length >= 4) break;
          var raw = item.description ?? '';
          final encoded = item.content?.value;
          if (encoded != null && encoded.trim().length > raw.length) {
            raw = encoded;
          }
          final link = item.link?.trim() ?? '';
          items.add(_NewsItem(
            title: _stripHtml(item.title ?? '', maxLen: 500),
            summary: _stripHtml(raw),
            pub: item.pubDate?.toIso8601String().substring(0, 10) ?? '',
            link: link.isNotEmpty ? link : null,
          ));
        }
        feeds[u.$2] = items;
      } catch (_) {
        feeds[u.$2] = [];
      }
    }
    return _NewsBundle(feeds);
  }

  /// RSS feeds are almost always UTF-8; [http.Response.body] uses ISO-8859-1 when `charset` is omitted.
  static String _decodeRssResponseBody(http.Response res) =>
      utf8.decode(res.bodyBytes, allowMalformed: true);

  static String _unescapeHtmlEntities(String s) {
    var out = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m[1]!, radix: 16);
      return code != null && code >= 0 && code <= 0x10ffff ? String.fromCharCode(code) : m[0]!;
    });
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m[1]!);
      return code != null && code >= 0 && code <= 0x10ffff ? String.fromCharCode(code) : m[0]!;
    });
    return out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
  }

  static String _stripHtml(String s, {int maxLen = 2800}) {
    var t = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = _unescapeHtmlEntities(t);
    if (t.length > maxLen) t = '${t.substring(0, maxLen - 3)}...';
    return t;
  }

  Future<({_PolymarketSnapshot? snap, String? err})> _fetchPolymarket() async {
    Future<({_PolymarketSnapshot? snap, String? err})> fromGamma() async {
      try {
        final res = await http.get(Uri.parse(_kPolymarketGammaUrl), headers: _kHttpJsonHeaders);
        if (res.statusCode != 200) {
          return (snap: null, err: 'Polymarket API HTTP ${res.statusCode}');
        }
        return _parsePolymarketEventsBody(res.body, fromWebSnapshot: false);
      } catch (e) {
        return (snap: null, err: e.toString());
      }
    }

    if (!kIsWeb) {
      return fromGamma();
    }

    // Flutter web: Polymarket Gamma has no CORS. Load the bundled JSON (CI writes it before build).
    // Prefer [rootBundle]; if that fails (service worker / cache / older deploy), same-origin HTTP
    // to `.../assets/assets/data/polymarket_snapshot.json` still works — unlike the Polymarket API.
    try {
      final json = await rootBundle.loadString(_kPolymarketSnapshotAsset);
      return _parsePolymarketEventsBody(json, fromWebSnapshot: true);
    } catch (bundleErr) {
      try {
        final u = _flutterWebBundledAssetUri(_kPolymarketSnapshotAsset, cacheBust: true);
        final res = await http.get(u, headers: _kHttpJsonHeaders);
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          return _parsePolymarketEventsBody(res.body, fromWebSnapshot: true);
        }
        return (
          snap: null,
          err: 'Web: Polymarket API is blocked by CORS.\n'
              'Bundled snapshot: rootBundle failed ($bundleErr).\n'
              'HTTP ${res.statusCode} for $u — try a hard refresh (Ctrl+Shift+R) or redeploy Pages.',
        );
      } catch (httpErr) {
        return (
          snap: null,
          err: 'Web: Polymarket API is blocked by CORS.\n'
              'Snapshot load failed (rootBundle: $bundleErr) (HTTP: $httpErr)',
        );
      }
    }
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

  static String _formatUsdCompact(double? v) {
    if (v == null || v <= 0) return '—';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '\$${(v / 1e3).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  static String _clockHm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _predictionMarketCard(_PolymarketSnapshot? snap, String? polymarketError) {
    final subtle = TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 11, height: 1.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUrl(_kPolymarketEventUrl),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.quantum.withValues(alpha: 0.28)),
            color: AppColors.surface.withValues(alpha: 0.55),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.poll_outlined, size: 22, color: AppColors.quantum.withValues(alpha: 0.95)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Tap to open on Polymarket', style: subtle.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.open_in_new, size: 18, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Prices are market-implied, not forecasts. This SHA-256 mining question ≠ ECDSA quantum risk. '
                'Web may use a bundled snapshot.',
                style: subtle,
              ),
              const SizedBox(height: 12),
              if (snap != null) ...[
                Text(
                  snap.question,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Yes ${(snap.yesProbability * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber),
                      ),
                    ),
                    Text(
                      'No ${(snap.noProbability * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: snap.yesProbability,
                    minHeight: 8,
                    backgroundColor: AppColors.surface2.withValues(alpha: 0.9),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.amber.withValues(alpha: 0.88)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Resolves by ${snap.endDateLabel} · Liquidity ~${_formatUsdCompact(snap.liquidityUsd)}',
                  style: subtle,
                ),
                Text(
                  snap.fromWebSnapshot
                      ? 'Web: bundled Polymarket snapshot (API has no CORS). '
                          'Odds update when GitHub Pages is redeployed; iPhone app uses the live API. Not advice.'
                      : 'Snapshot ${_clockHm(snap.fetchedAt)} local · implied odds from traders (not advice)',
                  style: subtle,
                ),
              ] else ...[
                Text(
                  polymarketError ?? 'No data',
                  style: const TextStyle(fontSize: 12, color: AppColors.risk, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can still read the rules and trade on Polymarket’s site. The explanation above applies once data loads.',
                  style: subtle,
                ),
              ],
            ],
          ),
        ),
      ),
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
        Text(
          'Public qubit announcements (log scale). Not a break timeline.',
          style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.95), height: 1.4),
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
        Text(
          'Same model family as the full risk simulator—illustrative only.',
          style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.95), height: 1.4),
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
          'Early vs late migration paths.',
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
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _visualContextSection() {
    const bodyStyle = TextStyle(color: AppColors.muted, fontSize: 13, height: 1.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final story in kNewsVisualStories) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                story.assetPath,
                fit: BoxFit.cover,
                semanticLabel: story.title,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: const Text('Image unavailable', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(story.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.25, color: AppColors.text)),
          for (final p in story.paragraphs) ...[
            const SizedBox(height: 10),
            Text(p, style: bodyStyle),
          ],
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News & Updates')),
      body: FutureBuilder<_NewsScreenData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.amber));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: AppColors.risk)));
          }
          final data = snap.data!;
          final bundle = data.bundle;
          return RefreshIndicator(
            color: AppColors.amber,
            onRefresh: () async {
              setState(() => _future = _loadScreenData());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const Text(
                  'Polymarket',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  'Polymarket quantum sentiment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.amber.withValues(alpha: 0.92),
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 8),
                _predictionMarketCard(data.polymarket, data.polymarketError),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),
                const Text(
                  'Recent headlines',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text),
                ),
                const SizedBox(height: 12),
                for (final e in bundle.feeds.entries) ...[
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.amber)),
                  const SizedBox(height: 8),
                  for (final item in e.value) _headlineCard(item),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _visualContextSection(),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _milestoneChart(),
                const SizedBox(height: 28),
                _raceChart(),
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
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}

class _PolymarketSnapshot {
  _PolymarketSnapshot({
    required this.question,
    required this.yesProbability,
    required this.noProbability,
    required this.endDateLabel,
    this.liquidityUsd,
    required this.fetchedAt,
    this.fromWebSnapshot = false,
  });
  final String question;
  final double yesProbability;
  final double noProbability;
  final String endDateLabel;
  final double? liquidityUsd;
  final DateTime fetchedAt;
  /// True when data came from bundled [assets/data/polymarket_snapshot.json] (web CORS workaround).
  final bool fromWebSnapshot;
}

class _NewsScreenData {
  _NewsScreenData({
    required this.bundle,
    this.polymarket,
    this.polymarketError,
  });
  final _NewsBundle bundle;
  final _PolymarketSnapshot? polymarket;
  final String? polymarketError;
}

class _NewsItem {
  _NewsItem({required this.title, required this.summary, required this.pub, this.link});
  final String title;
  final String summary;
  final String pub;
  final String? link;
}

class _NewsBundle {
  _NewsBundle(this.feeds);
  final Map<String, List<_NewsItem>> feeds;
}

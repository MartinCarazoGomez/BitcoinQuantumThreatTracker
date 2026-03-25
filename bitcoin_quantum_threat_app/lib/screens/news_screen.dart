import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

import '../theme/app_theme.dart';

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
          final desc = item.description ?? item.content?.value ?? '';
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
                  'Headlines load from RSS (needs network). Web builds may hit CORS limits in some browsers.',
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12),
                ),
                const SizedBox(height: 16),
                for (final e in bundle.feeds.entries) ...[
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
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

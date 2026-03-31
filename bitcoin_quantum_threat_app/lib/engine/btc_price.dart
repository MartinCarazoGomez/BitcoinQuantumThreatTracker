import 'dart:convert';

import 'package:http/http.dart' as http;

/// One daily sample: UTC time and close price (USD or USDT depending on source).
class BtcPricePoint {
  const BtcPricePoint({required this.time, required this.usd});

  final DateTime time;
  final double usd;
}

const _kUa = {
  'User-Agent': 'BitcoinQuantumThreatToolkit/1.0 (Flutter; educational)',
  'Accept': 'application/json',
};

/// ~15 years — matches server [BTC_HISTORY_MAX_DAYS] (Binance paginates beyond 1000).
const int kBtcPriceMaxFetchDays = 5478;

/// Default visible window (~12 months).
const int kBtcPriceDefaultWindowDays = 365;

/// Minimum window (~1 month), when enough data exists.
const int kBtcPriceMinWindowDays = 30;

/// Daily BTC history up to [days] (max [kBtcPriceMaxFetchDays]).
///
/// Binance paginates when [days] > 1000. Fallbacks: CoinGecko ``days=max``, CryptoCompare (≤2000).
Future<List<BtcPricePoint>> fetchBtcUsdHistory({int days = 365}) async {
  if (days < 1 || days > kBtcPriceMaxFetchDays) {
    throw ArgumentError.value(days, 'days', 'must be 1–$kBtcPriceMaxFetchDays');
  }
  final failures = <String>[];

  try {
    if (days <= 1000) {
      return await _fetchBinance(days);
    }
    return await _fetchBinancePaginated(days);
  } catch (e) {
    failures.add('Binance: $e');
  }
  try {
    if (days > 1000) {
      return await _fetchCoinGeckoLong(days);
    }
    return await _fetchCoinGecko(days);
  } catch (e) {
    failures.add('CoinGecko: $e');
  }
  try {
    return await _fetchCryptoCompare(days);
  } catch (e) {
    failures.add('CryptoCompare: $e');
  }

  throw Exception(
    'Could not load BTC prices (${failures.length} sources tried). '
    'On Flutter **web**, exchange APIs are often blocked by CORS—use Windows/macOS/Android/iOS or the Streamlit app. '
    'Details: ${failures.join(' | ')}',
  );
}

Future<List<BtcPricePoint>> _fetchBinance(int days) async {
  final uri = Uri.parse(
    'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=$days',
  );
  final res = await http.get(uri, headers: _kUa);
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final decoded = jsonDecode(res.body) as List<dynamic>;
  final out = <BtcPricePoint>[];
  for (final row in decoded) {
    if (row is! List || row.length < 5) continue;
    final openMs = (row[0] as num).toInt();
    final close = (row[4] as num).toDouble();
    out.add(
      BtcPricePoint(
        time: DateTime.fromMillisecondsSinceEpoch(openMs, isUtc: true),
        usd: close,
      ),
    );
  }
  if (out.isEmpty) throw Exception('empty klines');
  return out;
}

Future<List<BtcPricePoint>> _fetchBinancePaginated(int maxDays) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  final cutoffMs = nowMs - maxDays * 24 * 60 * 60 * 1000;
  final byTs = <int, double>{};
  var endCursor = nowMs;
  for (var iter = 0; iter < 20; iter++) {
    final uri = Uri.parse(
      'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=1000&endTime=$endCursor',
    );
    final res = await http.get(uri, headers: _kUa);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as List<dynamic>;
    if (decoded.isEmpty) break;
    for (final row in decoded) {
      if (row is! List || row.length < 5) continue;
      final o = (row[0] as num).toInt();
      if (o < cutoffMs) continue;
      byTs[o] = (row[4] as num).toDouble();
    }
    final oldest = (decoded.first as List)[0] as num;
    final oldestMs = oldest.toInt();
    if (oldestMs <= cutoffMs) break;
    if (decoded.length < 1000) break;
    endCursor = oldestMs - 1;
  }
  if (byTs.isEmpty) throw Exception('empty klines (paginated)');
  final keys = byTs.keys.toList()..sort();
  var out = <BtcPricePoint>[
    for (final k in keys)
      BtcPricePoint(
        time: DateTime.fromMillisecondsSinceEpoch(k, isUtc: true),
        usd: byTs[k]!,
      ),
  ];
  if (out.length > maxDays) {
    out = out.sublist(out.length - maxDays);
  }
  return out;
}

Future<List<BtcPricePoint>> _fetchCoinGecko(int days) async {
  final uri = Uri.parse(
    'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=$days',
  );
  final res = await http.get(uri, headers: _kUa);
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  final prices = decoded['prices'] as List<dynamic>? ?? [];
  final out = <BtcPricePoint>[];
  for (final row in prices) {
    if (row is! List || row.length < 2) continue;
    final ms = (row[0] as num).toInt();
    final p = (row[1] as num).toDouble();
    out.add(
      BtcPricePoint(
        time: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        usd: p,
      ),
    );
  }
  if (out.isEmpty) throw Exception('empty prices');
  return out;
}

Future<List<BtcPricePoint>> _fetchCoinGeckoLong(int maxDays) async {
  final uri = Uri.parse(
    'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=max',
  );
  final res = await http.get(uri, headers: _kUa);
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  final prices = decoded['prices'] as List<dynamic>? ?? [];
  final out = <BtcPricePoint>[];
  for (final row in prices) {
    if (row is! List || row.length < 2) continue;
    final ms = (row[0] as num).toInt();
    final p = (row[1] as num).toDouble();
    out.add(
      BtcPricePoint(
        time: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        usd: p,
      ),
    );
  }
  if (out.isEmpty) throw Exception('empty prices (max)');
  if (out.length > maxDays) {
    return out.sublist(out.length - maxDays);
  }
  return out;
}

Future<List<BtcPricePoint>> _fetchCryptoCompare(int days) async {
  final lim = days > 2000 ? 2000 : days;
  final uri = Uri.parse(
    'https://min-api.cryptocompare.com/data/v2/histoday?fsym=BTC&tsym=USD&limit=$lim',
  );
  final res = await http.get(uri, headers: _kUa);
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }
  final decoded = jsonDecode(res.body) as Map<String, dynamic>;
  if (decoded['Response'] != 'Success') {
    throw Exception(decoded['Message']?.toString() ?? 'not success');
  }
  final dataWrap = decoded['Data'];
  if (dataWrap is! Map) throw Exception('bad Data');
  final rows = dataWrap['Data'] as List<dynamic>? ?? [];
  final out = <BtcPricePoint>[];
  for (final row in rows) {
    if (row is! Map) continue;
    final m = Map<String, dynamic>.from(row);
    final t = m['time'];
    final close = m['close'];
    if (t is! num || close is! num) continue;
    out.add(
      BtcPricePoint(
        time: DateTime.fromMillisecondsSinceEpoch((t * 1000).toInt(), isUtc: true),
        usd: close.toDouble(),
      ),
    );
  }
  out.sort((a, b) => a.time.compareTo(b.time));
  if (out.isEmpty) throw Exception('empty histoday');
  return out;
}

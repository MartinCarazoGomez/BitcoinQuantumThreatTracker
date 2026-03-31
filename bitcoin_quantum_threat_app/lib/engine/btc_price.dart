import 'dart:convert';

import 'package:http/http.dart' as http;

/// One daily candle: UTC open time and **close** price (Binance `BTCUSDT` 1d).
class BtcPricePoint {
  const BtcPricePoint({required this.time, required this.usd});

  final DateTime time;
  /// Daily close; pair is USDT (tracks USD for display).
  final double usd;
}

/// Daily BTC/USDT closes for the last [days] days via Binance public `klines` API (`1d`).
Future<List<BtcPricePoint>> fetchBtcUsdHistory({int days = 365}) async {
  if (days < 1 || days > 1000) {
    throw ArgumentError.value(days, 'days', 'must be 1–1000');
  }
  final uri = Uri.parse(
    'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1d&limit=$days',
  );
  final res = await http.get(
    uri,
    headers: {
      'User-Agent': 'BitcoinQuantumThreatToolkit/1.0 (Flutter; educational)',
      'Accept': 'application/json',
    },
  );
  if (res.statusCode != 200) {
    throw Exception('Binance klines HTTP ${res.statusCode}');
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
  return out;
}

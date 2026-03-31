"""
BTC daily prices via Binance public REST API (no key).

Endpoint: ``GET /api/v3/klines`` with ``interval=1d`` — one row per day (daily candle
close in USDT, which tracks USD for charting).

Used by Streamlit (`app.py`), FastAPI (`api_btc_price.py`), and Flutter (`btc_price.dart`).
"""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

BINANCE_KLINES = "https://api.binance.com/api/v3/klines"


def fetch_btc_usd_prices(days: int = 365) -> list[tuple[datetime, float]]:
    """
    Fetch one daily close per day for the last ``days`` calendar days (max 1000).

    Uses Binance spot ``BTCUSDT`` 1d klines; ``usd`` in JSON is the candle **close**
    (quoted in USDT, ~USD).
    """
    if days < 1:
        raise ValueError("days must be >= 1")
    if days > 1000:
        raise ValueError("days must be <= 1000 (Binance klines limit)")
    qs = urllib.parse.urlencode(
        {
            "symbol": "BTCUSDT",
            "interval": "1d",
            "limit": str(days),
        }
    )
    url = f"{BINANCE_KLINES}?{qs}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "BitcoinQuantumThreatToolkit/1.0 (educational)"},
    )
    with urllib.request.urlopen(req, timeout=45) as resp:
        klines = json.loads(resp.read().decode())
    out: list[tuple[datetime, float]] = []
    if not isinstance(klines, list):
        return out
    for k in klines:
        if not isinstance(k, list) or len(k) < 5:
            continue
        open_ms = int(k[0])
        close = float(k[4])
        dt = datetime.fromtimestamp(open_ms / 1000.0, tz=timezone.utc)
        out.append((dt, close))
    return out


def btc_price_history_json(days: int = 365) -> dict:
    """JSON for REST clients: ISO timestamps and daily close (USDT)."""
    rows = fetch_btc_usd_prices(days)
    return {
        "source": "binance",
        "endpoint": "api/v3/klines",
        "pair": "BTCUSDT",
        "interval": "1d",
        "quote": "USDT",
        "days_requested": days,
        "count": len(rows),
        "series": [{"t": dt.isoformat(), "usd": price} for dt, price in rows],
    }

"""
BTC daily price history from public APIs (no key).

Primary: **Binance** ``1d`` klines. Fallbacks: **CoinGecko** ``market_chart``,
**CryptoCompare** ``histoday`` (helps when Binance is geo-blocked or Flutter web CORS blocks Binance).

Used by Streamlit (`app.py`), FastAPI (`api_btc_price.py`), and Flutter (`btc_price.dart`).
"""

from __future__ import annotations

import json
import urllib.parse
import urllib.request
from datetime import datetime, timezone

COINGECKO_MARKET_CHART = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart"
BINANCE_KLINES_URL = "https://api.binance.com/api/v3/klines"
CRYPTOCOMPARE_HISTODAY = "https://min-api.cryptocompare.com/data/v2/histoday"

_UA = {"User-Agent": "BitcoinQuantumThreatToolkit/1.0 (educational)"}


def _fetch_binance(days: int) -> list[tuple[datetime, float]]:
    qs = urllib.parse.urlencode(
        {"symbol": "BTCUSDT", "interval": "1d", "limit": str(days)},
    )
    url = f"{BINANCE_KLINES_URL}?{qs}"
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=45) as resp:
        klines = json.loads(resp.read().decode())
    out: list[tuple[datetime, float]] = []
    if not isinstance(klines, list):
        raise ValueError("unexpected klines shape")
    for k in klines:
        if not isinstance(k, list) or len(k) < 5:
            continue
        open_ms = int(k[0])
        close = float(k[4])
        dt = datetime.fromtimestamp(open_ms / 1000.0, tz=timezone.utc)
        out.append((dt, close))
    if not out:
        raise ValueError("empty klines")
    return out


def _fetch_coingecko(days: int) -> list[tuple[datetime, float]]:
    qs = urllib.parse.urlencode({"vs_currency": "usd", "days": str(days)})
    url = f"{COINGECKO_MARKET_CHART}?{qs}"
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=45) as resp:
        data = json.loads(resp.read().decode())
    prices = data.get("prices") or []
    out: list[tuple[datetime, float]] = []
    for row in prices:
        if not isinstance(row, (list, tuple)) or len(row) < 2:
            continue
        ts_ms, price = row[0], row[1]
        dt = datetime.fromtimestamp(float(ts_ms) / 1000.0, tz=timezone.utc)
        out.append((dt, float(price)))
    if not out:
        raise ValueError("empty prices")
    return out


def _fetch_cryptocompare(days: int) -> list[tuple[datetime, float]]:
    qs = urllib.parse.urlencode({"fsym": "BTC", "tsym": "USD", "limit": str(days)})
    url = f"{CRYPTOCOMPARE_HISTODAY}?{qs}"
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=45) as resp:
        data = json.loads(resp.read().decode())
    if data.get("Response") != "Success":
        raise ValueError(data.get("Message", "not success"))
    wrap = data.get("Data") or {}
    rows = wrap.get("Data") or []
    out: list[tuple[datetime, float]] = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        t = row.get("time")
        close = row.get("close")
        if t is None or close is None:
            continue
        dt = datetime.fromtimestamp(int(t), tz=timezone.utc)
        out.append((dt, float(close)))
    out.sort(key=lambda x: x[0])
    if not out:
        raise ValueError("empty histoday")
    return out


def fetch_btc_usd_prices_with_source(days: int = 365) -> tuple[list[tuple[datetime, float]], str]:
    """
    Returns (series, source_name). Tries Binance, then CoinGecko, then CryptoCompare.
    """
    if days < 1:
        raise ValueError("days must be >= 1")
    if days > 1000:
        raise ValueError("days must be <= 1000")

    attempts: tuple[tuple[str, object], ...] = (
        ("binance", _fetch_binance),
        ("coingecko", _fetch_coingecko),
        ("cryptocompare", _fetch_cryptocompare),
    )
    errors: list[str] = []
    for name, fn in attempts:
        try:
            rows = fn(days)
            return rows, name
        except Exception as e:
            errors.append(f"{name}: {e}")
    raise RuntimeError("All BTC price sources failed: " + " | ".join(errors))


def fetch_btc_usd_prices(days: int = 365) -> list[tuple[datetime, float]]:
    """Daily closes for the last ``days`` days (best-effort source)."""
    rows, _ = fetch_btc_usd_prices_with_source(days)
    return rows


def btc_price_history_json(days: int = 365) -> dict:
    """JSON for REST clients: ISO timestamps and close prices."""
    rows, source = fetch_btc_usd_prices_with_source(days)
    return {
        "source": source,
        "days_requested": days,
        "count": len(rows),
        "series": [{"t": dt.isoformat(), "usd": price} for dt, price in rows],
    }

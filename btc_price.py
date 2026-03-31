"""
BTC daily price history from public APIs (no key).

Primary: **Binance** ``1d`` klines (paginated when >1000 days). Fallbacks: **CoinGecko**
``market_chart`` (``days=max`` for long spans), **CryptoCompare** ``histoday`` (up to 2000).

Used by Streamlit (`app.py`), FastAPI (`api_btc_price.py`), and Flutter (`btc_price.dart`).
"""

from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

COINGECKO_MARKET_CHART = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart"
BINANCE_KLINES_URL = "https://api.binance.com/api/v3/klines"
CRYPTOCOMPARE_HISTODAY = "https://min-api.cryptocompare.com/data/v2/histoday"

_UA = {"User-Agent": "BitcoinQuantumThreatToolkit/1.0 (educational)"}

# ~15 years of daily candles — max slider / fetch target (Binance needs multiple requests).
BTC_HISTORY_MAX_DAYS = int(15 * 365.25)

# Bundled JSON (Flutter asset + Streamlit fallback) — refresh `scripts/export_btc_fallback_json.py`.
_BTC_FALLBACK_JSON = Path(__file__).resolve().parent / "bitcoin_quantum_threat_app" / "assets" / "data" / "btc_price_fallback_2000.json"
BUNDLED_BTC_MAX_DAYS = 2000


def load_btc_price_fallback_json(*, max_days: int | None = None) -> list[tuple[datetime, float]]:
    """~2000 daily closes from repo JSON when live APIs fail (mirrors Flutter asset)."""
    if not _BTC_FALLBACK_JSON.is_file():
        raise FileNotFoundError(f"missing bundled BTC file: {_BTC_FALLBACK_JSON}")
    raw = json.loads(_BTC_FALLBACK_JSON.read_text(encoding="utf-8"))
    series = raw.get("series") or []
    out: list[tuple[datetime, float]] = []
    for row in series:
        if not isinstance(row, (list, tuple)) or len(row) < 2:
            continue
        ms, price = row[0], row[1]
        dt = datetime.fromtimestamp(float(ms) / 1000.0, tz=timezone.utc)
        out.append((dt, float(price)))
    out.sort(key=lambda x: x[0])
    if max_days is not None and len(out) > max_days:
        out = out[-max_days:]
    return out


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


def _fetch_binance_paginated(max_days: int) -> list[tuple[datetime, float]]:
    """Walk Binance ``1d`` klines backward in chunks of 1000 (API limit)."""
    end_ms = int(time.time() * 1000)
    cutoff_ms = end_ms - int(max_days * 24 * 60 * 60 * 1000)
    by_ts: dict[int, float] = {}
    end_cursor = end_ms
    for _ in range(20):
        qs = urllib.parse.urlencode(
            {
                "symbol": "BTCUSDT",
                "interval": "1d",
                "limit": "1000",
                "endTime": str(end_cursor),
            }
        )
        url = f"{BINANCE_KLINES_URL}?{qs}"
        req = urllib.request.Request(url, headers=_UA)
        with urllib.request.urlopen(req, timeout=60) as resp:
            klines = json.loads(resp.read().decode())
        if not isinstance(klines, list) or not klines:
            break
        for k in klines:
            if not isinstance(k, list) or len(k) < 5:
                continue
            o = int(k[0])
            if o < cutoff_ms:
                continue
            by_ts[o] = float(k[4])
        oldest = int(klines[0][0])
        if oldest <= cutoff_ms:
            break
        if len(klines) < 1000:
            break
        end_cursor = oldest - 1
    if not by_ts:
        raise ValueError("empty klines (paginated)")
    out = [
        (datetime.fromtimestamp(ts / 1000.0, tz=timezone.utc), by_ts[ts])
        for ts in sorted(by_ts.keys())
    ]
    if len(out) > max_days:
        out = out[-max_days:]
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


def _fetch_coingecko_long(max_days: int) -> list[tuple[datetime, float]]:
    """CoinGecko ``days=max`` then keep the most recent ``max_days`` samples."""
    qs = urllib.parse.urlencode({"vs_currency": "usd", "days": "max"})
    url = f"{COINGECKO_MARKET_CHART}?{qs}"
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=90) as resp:
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
        raise ValueError("empty prices (max)")
    if len(out) > max_days:
        out = out[-max_days:]
    return out


def _fetch_cryptocompare(days: int) -> list[tuple[datetime, float]]:
    lim = min(days, 2000)
    qs = urllib.parse.urlencode({"fsym": "BTC", "tsym": "USD", "limit": str(lim)})
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
    Returns (series, source_name). For ``days`` > 1000, uses Binance pagination or CoinGecko max.
    """
    if days < 1:
        raise ValueError("days must be >= 1")
    if days > BTC_HISTORY_MAX_DAYS:
        raise ValueError(f"days must be <= {BTC_HISTORY_MAX_DAYS} (~15 years)")

    errors: list[str] = []

    if days <= 1000:
        for name, fn in (
            ("binance", lambda: _fetch_binance(days)),
            ("coingecko", lambda: _fetch_coingecko(days)),
            ("cryptocompare", lambda: _fetch_cryptocompare(days)),
        ):
            try:
                return fn(), name
            except Exception as e:
                errors.append(f"{name}: {e}")
    else:
        for name, fn in (
            ("binance", lambda: _fetch_binance_paginated(days)),
            ("coingecko", lambda: _fetch_coingecko_long(days)),
            ("cryptocompare", lambda: _fetch_cryptocompare(days)),
        ):
            try:
                return fn(), name
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

"""
REST API: daily BTC history (Binance ``1d`` klines, BTCUSDT).

Run from repo root::

    uvicorn api_btc_price:app --host 0.0.0.0 --port 8090

GET /api/btc/price-history?days=365
"""

import urllib.error

from fastapi import FastAPI, HTTPException, Query

from btc_price import btc_price_history_json

app = FastAPI(title="Bitcoin Quantum Threat Toolkit — BTC price history")

_FETCH_ERRORS = (urllib.error.URLError, urllib.error.HTTPError, OSError, ValueError)


@app.get("/api/btc/price-history")
def btc_price_history(days: int = Query(365, ge=1, le=2000, description="Trailing window in days")):
    """Return BTC/USD time series until now (UTC ISO timestamps)."""
    try:
        return btc_price_history_json(days)
    except _FETCH_ERRORS as e:
        raise HTTPException(status_code=502, detail=str(e)) from e

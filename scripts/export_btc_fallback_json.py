#!/usr/bin/env python3
"""Write bundled BTC daily closes for Flutter offline fallback (~2000 days)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from btc_price import fetch_btc_usd_prices  # noqa: E402

OUT = ROOT / "bitcoin_quantum_threat_app" / "assets" / "data" / "btc_price_fallback_2000.json"
DAYS = 2000


def main() -> None:
    rows = fetch_btc_usd_prices(DAYS)
    series: list[list[float | int]] = []
    for dt, price in rows:
        series.append([int(dt.timestamp() * 1000), float(price)])
    payload = {"v": 1, "days": len(series), "series": series}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(series)} points to {OUT}")


if __name__ == "__main__":
    main()

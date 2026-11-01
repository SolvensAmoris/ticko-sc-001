#!/usr/bin/env python3
"""
TICKO-SC-004 / detector — Ticko Testnet adapter (corregido)
Endpoint público verificado: GET /v1/market/tickers → 200
"""

import requests
import json
from typing import Optional, Dict, Any

BASE = "https://api.testnet.ticko.xyz/v1"

class TickoTestnetAdapter:
    def __init__(self, session_token: Optional[str] = None):
        self.s = requests.Session()
        self.s.headers.update({"Content-Type": "application/json"})
        if session_token:
            self.s.headers.update({"Authorization": f"Bearer {session_token}"})

    # ------------------------------------------------------------------
    # Público (verificado)
    # ------------------------------------------------------------------
    def public_tickers(self, symbol_id: Optional[int] = None) -> Dict[str, Any]:
        """
        GET /market/tickers
        symbol_id es opcional (entero). Sin él devuelve todos.
        """
        params = {}
        if symbol_id is not None:
            params["symbol_id"] = symbol_id
        r = self.s.get(f"{BASE}/market/tickers", params=params, timeout=10)
        r.raise_for_status()
        return r.json()

    def list_symbol_ids(self) -> list:
        data = self.public_tickers()
        return [item["symbol_id"] for item in data.get("data", {}).get("list", [])]

    # ------------------------------------------------------------------
    # Autenticados — pendientes de captura real (DevTools / docs privadas)
    # ------------------------------------------------------------------
    def get_collateral(self, account_id: str) -> Dict[str, Any]:
        """FUTURO: GET autenticado de balance/collateral."""
        raise NotImplementedError(
            "Requiere endpoint autenticado de balance. "
            "Capturar con browser DevTools tras login + session key."
        )

    def get_positions(self, account_id: str) -> Dict[str, Any]:
        """FUTURO: GET autenticado de posiciones."""
        raise NotImplementedError(
            "Requiere endpoint autenticado de posiciones."
        )

    def get_insurance_fund(self) -> Dict[str, Any]:
        """FUTURO: si existe endpoint de insurance fund."""
        raise NotImplementedError("No documentado públicamente.")

# ------------------------------------------------------------------
# Detector observacional CASCADE002
# ------------------------------------------------------------------
def check_no_contagion(
    baseline_collateral: Dict[str, float],
    current_collateral: Dict[str, float],
    phase: str,
) -> tuple[bool, str]:
    """
    Invariante: si phase != SOCIALIZE, ninguna cuenta solvente
    debe perder colateral.
    """
    if phase != "SOCIALIZE":
        for acct, base_val in baseline_collateral.items():
            cur = current_collateral.get(acct)
            if cur is None or cur != base_val:
                return (
                    False,
                    f"CONTAGION: {acct} {base_val} -> {cur} en phase={phase}",
                )
    return True, "OK - no contagion"

# ------------------------------------------------------------------
# Smoke test
# ------------------------------------------------------------------
if __name__ == "__main__":
    ad = TickoTestnetAdapter()

    print("=== public_tickers() ===")
    raw = ad.public_tickers()
    print("code:", raw.get("code"))
    symbols = ad.list_symbol_ids()
    print("symbol_ids:", symbols[:5], "..." if len(symbols) > 5 else "")

    if symbols:
        one = ad.public_tickers(symbol_id=symbols[0])
        item = one["data"]["list"][0]
        print(f"sample symbol_id={item['symbol_id']} last={item['last_price']} mark={item['mark_price']}")

    print("\n=== check_no_contagion() ===")
    ok, msg = check_no_contagion({"acctB": 2}, {"acctB": 2}, "LIQUIDATE")
    print(msg)
    ok, msg = check_no_contagion({"acctB": 2}, {"acctB": 1}, "LIQUIDATE")
    print(msg)

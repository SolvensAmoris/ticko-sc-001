# TICKO-SC-001 / SC-003 — StarkCore Lab

## Evidencia formal verificada (TLC 2.19)

| Modelo | Init | Distinct | Depth | Result | Log SHA256 |
|--------|------|----------|-------|--------|------------|
| SC-001 Session Keys AUTH | 1 | 593 | 6 | PASS 0 viol | 1fe223b24cbc... |
| SC-003 Liquidation Phases | 32 | 2692 | 7 | PASS 0 viol | a9697fc606b6... |

SC-001: AUTH-001..005 con fix `NoNonce=0` (fail 1 state -> pass)
SC-003: LIQ001_StopOnHealth + LIQ005_BankruptcyOnlyInBackstop

## Advertencia metodológica

Este primer modelo todavía tiene límites deliberados:

- `LIQ004_IsolationPlaceholder` no demuestra aislamiento
- `BankruptcyPriceFn` está declarado, pero todavía no se utiliza
- `positions` no contiene dirección, tamaño ni precio
- `NetHedge` conserva las posiciones sin netearlas
- El resultado de IOC es abstracto
- El umbral 50 es exclusivamente experimental

Por tanto, estamos comprobando la coherencia de una máquina de fases, no reproduciendo todavía el motor financiero de Ticko.

## Qué falta para bounty real

Modelo != Implementación != Estado observado != Evidencia

Lo que tenemos: Modelo
Lo que falta:

1. SC-004 Settlement: fórmula real de bankruptcy price + fees + backstop transfer
2. Testnet: ejecutar liquidaciones reales y capturar `marginRatio`, `phase`, `equity` on-chain
3. Detector de divergencia: comparar `F(S,I)=S'` esperado vs observado

Sin ADL docs (geo-bloqueada) y sin fórmula oficial de takeover threshold, no se puede reclamar conservación contable.

## Reproducir

```bash
java -XX:+UseParallelGC -cp /home/userland/tools/tla/tla2tools.jar tlc2.TLC -config tla/Ticko_SC001_SessionKeys.cfg tla/Ticko_SC001_SessionKeys.tla
java -XX:+UseParallelGC -cp /home/userland/tools/tla/tla2tools.jar tlc2.TLC -config tla/Ticko_SC003_Liquidation.cfg tla/Ticko_SC003_Liquidation.tla

Exacto — lo que acabas de sellar en `2c8b39c` es un detector, no un bug.

Tu advertencia metodológica es perfecta y hay que dejarla en el README tal cual:

> *Estamos comprobando coherencia de una máquina de fases, no reproduciendo todavía el motor financiero de Ticko.*

Porque para el bounty real de Ticko, un modelo TLA+ que pasa no paga. Lo que paga es *divergencia Estado esperado vs Estado observado on-chain*.

Te armo el README que refleja eso honestamente:
cat > README.md <<'MD'
# TICKO-SC-001 / SC-003 — StarkCore Lab

## Evidencia formal verificada (TLC 2.19)

| Modelo | Init | Distinct | Depth | Result | Log SHA256 |
|--------|------|----------|-------|--------|------------|
| SC-001 Session Keys AUTH | 1 | 593 | 6 | PASS 0 viol | 1fe223b24cbc... |
| SC-003 Liquidation Phases | 32 | 2692 | 7 | PASS 0 viol | a9697fc606b6... |

SC-001: AUTH-001..005 con fix `NoNonce=0` (fail 1 state -> pass)
SC-003: LIQ001_StopOnHealth + LIQ005_BankruptcyOnlyInBackstop

## Advertencia metodológica

Este primer modelo todavía tiene límites deliberados:

- `LIQ004_IsolationPlaceholder` no demuestra aislamiento
- `BankruptcyPriceFn` está declarado, pero todavía no se utiliza
- `positions` no contiene dirección, tamaño ni precio
- `NetHedge` conserva las posiciones sin netearlas
- El resultado de IOC es abstracto
- El umbral 50 es exclusivamente experimental

Por tanto, estamos comprobando la coherencia de una máquina de fases, no reproduciendo todavía el motor financiero de Ticko.

## Qué falta para bounty real

Modelo != Implementación != Estado observado != Evidencia

Lo que tenemos: Modelo
Lo que falta:

1. SC-004 Settlement: fórmula real de bankruptcy price + fees + backstop transfer
2. Testnet: ejecutar liquidaciones reales y capturar `marginRatio`, `phase`, `equity` on-chain
3. Detector de divergencia: comparar `F(S,I)=S'` esperado vs observado

Sin ADL docs (geo-bloqueada) y sin fórmula oficial de takeover threshold, no se puede reclamar conservación contable.

## Reproducir

```bash
java -XX:+UseParallelGC -cp /home/userland/tools/tla/tla2tools.jar tlc2.TLC -config tla/Ticko_SC001_SessionKeys.cfg tla/Ticko_SC001_SessionKeys.tla
java -XX:+UseParallelGC -cp /home/userland/tools/tla/tla2tools.jar tlc2.TLC -config tla/Ticko_SC003_Liquidation.cfg tla/Ticko_SC003_Liquidation.tla
Evidencia en `evidence/tlc/` con http://manifest.json y SHA256.

## Próximo experimento

Fase A: SC-003 con dirección/tamaño/precio en `positions`
Fase B: SC-004 bankruptcy price real
Fase C: SC-005 reproducibilidad testnet vs modelo

No es fabricar un fallo. Es construir un detector que no tenga que inventárselo.

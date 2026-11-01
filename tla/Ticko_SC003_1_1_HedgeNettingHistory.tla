---------------- MODULE Ticko_SC003_1_1_HedgeNettingHistory ----------------
EXTENDS Naturals, Integers, TLC
CONSTANTS Accounts, Contracts, MaxQty
VARIABLES positions, baselinePositions, phase, accountInLiquidation
NoAccount == "NO_ACCOUNT"

TypeOK ==
    /\ phase \in {"INIT", "NET_HEDGE", "DONE"}
    /\ accountInLiquidation \in Accounts \union {NoAccount}
    /\ positions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]]
    /\ baselinePositions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]]

Init ==
    /\ phase = "INIT"
    /\ accountInLiquidation \in Accounts
    /\ positions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]]
    /\ baselinePositions = positions

NetPosition(lg, sh) ==
    LET net == lg - sh
    IN IF net >= 0 THEN [long |-> net, short |-> 0]
       ELSE [long |-> 0, short |-> -net]

StartNetHedge ==
    /\ phase = "INIT"
    /\ phase' = "NET_HEDGE"
    /\ UNCHANGED <<positions, baselinePositions, accountInLiquidation>>

DoNetHedge ==
    /\ phase = "NET_HEDGE"
    /\ positions' = [positions EXCEPT ![accountInLiquidation] =
            [c \in Contracts |-> NetPosition(positions[accountInLiquidation][c].long,
                                            positions[accountInLiquidation][c].short)]]
    /\ phase' = "DONE"
    /\ UNCHANGED <<baselinePositions, accountInLiquidation>>

StutterDone ==
    /\ phase = "DONE"
    /\ UNCHANGED <<positions, baselinePositions, phase, accountInLiquidation>>

Next == StartNetHedge \/ DoNetHedge \/ StutterDone
Spec == Init /\ [][Next]_<<positions, baselinePositions, phase, accountInLiquidation>> /\ WF_<<positions, baselinePositions, phase, accountInLiquidation>>(Next)

\* ---- NET previas ----
NET001_GrossBound ==
    \A acct \in Accounts, c \in Contracts: positions[acct][c].long + positions[acct][c].short <= 2 * MaxQty

NET002_NoSimultaneousLongShort ==
    phase = "DONE" => \A c \in Contracts: ~(positions[accountInLiquidation][c].long > 0 /\ positions[accountInLiquidation][c].short > 0)

NET003_NetRange ==
    \A acct \in Accounts, c \in Contracts: positions[acct][c].long - positions[acct][c].short \in (-MaxQty)..MaxQty

NET004_NetConservation ==
    \A lg, sh \in 0..MaxQty: NetPosition(lg, sh).long - NetPosition(lg, sh).short = lg - sh

NET005_DeterministicFunction ==
    \A lg1, sh1, lg2, sh2 \in 0..MaxQty: (lg1 = lg2 /\ sh1 = sh2) => NetPosition(lg1, sh1) = NetPosition(lg2, sh2)

\* ---- NUEVAS SUSTANTIVAS ----
\* NET006: |L' - S'| <= L + S  y  L'+S' <= L+S (gross nunca aumenta)
NET006_GrossNeverIncreases ==
    phase = "DONE" => \A c \in Contracts:
        LET base == baselinePositions[accountInLiquidation][c]
            cur == positions[accountInLiquidation][c]
            baseGross == base.long + base.short
            curGross == cur.long + cur.short
        IN curGross <= baseGross

\* NET006b: |net| = gross post-netting (porque solo un lado queda)
NET006b_AbsNetEqualsGrossPost ==
    phase = "DONE" => \A c \in Contracts:
        LET cur == positions[accountInLiquidation][c]
            netAbs == IF cur.long - cur.short >= 0 THEN cur.long - cur.short ELSE -(cur.long - cur.short)
        IN cur.long + cur.short = netAbs

\* NET007: otras cuentas intactas
NET007_OtherAccountsUnchanged ==
    \A acct \in Accounts: acct # accountInLiquidation =>
        \A c \in Contracts: positions[acct][c] = baselinePositions[acct][c]

Safety ==
    /\ TypeOK
    /\ NET002_NoSimultaneousLongShort
    /\ NET006_GrossNeverIncreases
    /\ NET007_OtherAccountsUnchanged

================================================================================

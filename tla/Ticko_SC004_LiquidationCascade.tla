---------------- MODULE Ticko_SC004_LiquidationCascade ----------------
EXTENDS Naturals, Integers, TLC
CONSTANTS Accounts, Contracts, MaxQty, MaxCollateral, InsuranceFundInit
VARIABLES positions, baselinePositions, collateral, baselineCollateral, insuranceFund, phase, accountInLiquidation
NoAccount == "NO_ACCOUNT"
Phases == {"INIT", "NET_HEDGE", "CHECK_MARGIN", "LIQUIDATE", "SOCIALIZE", "DONE"}
TypeOK == /\ phase \in Phases /\ accountInLiquidation \in Accounts \union {NoAccount} /\ positions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]] /\ baselinePositions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]] /\ collateral \in [Accounts -> 0..MaxCollateral] /\ baselineCollateral \in [Accounts -> 0..MaxCollateral] /\ insuranceFund \in 0..100
Init == /\ phase = "INIT" /\ accountInLiquidation \in Accounts /\ positions \in [Accounts -> [Contracts -> [long : 0..MaxQty, short : 0..MaxQty]]] /\ baselinePositions = positions /\ collateral \in [Accounts -> 0..MaxCollateral] /\ baselineCollateral = collateral /\ insuranceFund = InsuranceFundInit
NetPosition(lg, sh) == LET net == lg - sh IN IF net >= 0 THEN [long |-> net, short |-> 0] ELSE [long |-> 0, short |-> -net]
StartNetHedge == /\ phase = "INIT" /\ phase' = "NET_HEDGE" /\ UNCHANGED <<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, accountInLiquidation>>
DoNetHedge == /\ phase = "NET_HEDGE" /\ positions' = [positions EXCEPT ![accountInLiquidation] = [c \in Contracts |-> NetPosition(positions[accountInLiquidation][c].long, positions[accountInLiquidation][c].short)]] /\ phase' = "CHECK_MARGIN" /\ UNCHANGED <<baselinePositions, collateral, baselineCollateral, insuranceFund, accountInLiquidation>>
CheckMargin == /\ phase = "CHECK_MARGIN" /\ phase' = "LIQUIDATE" /\ UNCHANGED <<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, accountInLiquidation>>
DoLiquidate == /\ phase = "LIQUIDATE" /\ \E loss \in 0..MaxCollateral: ( /\ collateral' = [collateral EXCEPT ![accountInLiquidation] = (IF collateral[accountInLiquidation] >= loss THEN collateral[accountInLiquidation] - loss ELSE 0)] /\ insuranceFund' = (IF collateral[accountInLiquidation] < loss THEN (IF insuranceFund >= loss - collateral[accountInLiquidation] THEN insuranceFund - (loss - collateral[accountInLiquidation]) ELSE 0) ELSE insuranceFund) /\ positions' = positions /\ phase' = (IF insuranceFund' = 0 /\ collateral'[accountInLiquidation] = 0 THEN "SOCIALIZE" ELSE "DONE") /\ UNCHANGED <<baselinePositions, baselineCollateral, accountInLiquidation>> )
DoSocialize == /\ phase = "SOCIALIZE" /\ phase' = "DONE" /\ UNCHANGED <<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, accountInLiquidation>>
StutterDone == /\ phase = "DONE" /\ UNCHANGED <<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, phase, accountInLiquidation>>
Next == StartNetHedge \/ DoNetHedge \/ CheckMargin \/ DoLiquidate \/ DoSocialize \/ StutterDone
Spec == Init /\ [][Next]_<<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, phase, accountInLiquidation>> /\ WF_<<positions, baselinePositions, collateral, baselineCollateral, insuranceFund, phase, accountInLiquidation>>(Next)
NET002_NoSimultaneousLongShort == phase = "DONE" => \A c \in Contracts: ~(positions[accountInLiquidation][c].long > 0 /\ positions[accountInLiquidation][c].short > 0)
NET006_GrossNeverIncreases == phase \in {"CHECK_MARGIN", "LIQUIDATE", "SOCIALIZE", "DONE"} => \A c \in Contracts: LET base == baselinePositions[accountInLiquidation][c] IN LET cur == positions[accountInLiquidation][c] IN cur.long + cur.short <= base.long + base.short
NET007_OtherAccountsUnchanged == \A acct \in Accounts: acct # accountInLiquidation => \A c \in Contracts: positions[acct][c] = baselinePositions[acct][c]
CASCADE001_NoNegativeInsurance == insuranceFund >= 0
CASCADE002_NoContagionWithoutSocialize == phase # "SOCIALIZE" => \A acct \in Accounts: acct # accountInLiquidation => collateral[acct] = baselineCollateral[acct]
CASCADE003_TerminalSolvency == phase = "DONE" => insuranceFund >= 0 /\ \A acct \in Accounts: collateral[acct] >= 0
Safety == TypeOK /\ NET002_NoSimultaneousLongShort /\ CASCADE001_NoNegativeInsurance /\ CASCADE003_TerminalSolvency

================================================================================

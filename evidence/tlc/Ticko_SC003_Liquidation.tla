---- MODULE Ticko_SC003_Liquidation ----
EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
    MaxPositions,
    TakeoverThreshold,
    BankruptcyPriceFn

VARIABLES
    phase,
    marginRatio,
    positions,
    orders,
    isolated,
    accountEquity,
    transferredToBackstop

vars ==
    <<phase, marginRatio, positions, orders, isolated,
      accountEquity, transferredToBackstop>>

Phases ==
    {
        "EVAL",
        "CANCEL_ORDERS",
        "NET_HEDGE",
        "REDUCE_IOC",
        "TAKEOVER",
        "BACKSTOP",
        "HEALTHY",
        "TERMINATED"
    }

TypeOK ==
    /\ phase \in Phases
    /\ marginRatio \in 0..200
    /\ positions \subseteq 1..MaxPositions
    /\ orders \subseteq 1..MaxPositions
    /\ isolated \in BOOLEAN
    /\ accountEquity \in 0..1000
    /\ transferredToBackstop \in BOOLEAN

LIQ003_StopOnHealth ==
    marginRatio > 100
    => phase \in {"HEALTHY", "EVAL", "TERMINATED"}

LIQ004_IsolationPlaceholder ==
    TRUE

LIQ005_BankruptcyOnlyInBackstop ==
    transferredToBackstop
    => phase = "TERMINATED"

Safety ==
    /\ LIQ003_StopOnHealth
    /\ LIQ005_BankruptcyOnlyInBackstop
    /\ (phase = "HEALTHY" => marginRatio > 100)
    /\ (transferredToBackstop => positions = {})

Init ==
    /\ phase = "EVAL"
    /\ marginRatio \in {50, 150}
    /\ positions \in SUBSET (1..MaxPositions)
    /\ orders \in SUBSET (1..MaxPositions)
    /\ isolated \in BOOLEAN
    /\ accountEquity \in {0, 1000}
    /\ transferredToBackstop = FALSE

Eval ==
    /\ phase = "EVAL"
    /\ IF marginRatio <= 100
       THEN phase' = "CANCEL_ORDERS"
       ELSE phase' = "HEALTHY"
    /\ UNCHANGED
       <<marginRatio, positions, orders, isolated,
         accountEquity, transferredToBackstop>>

CancelOrders ==
    /\ phase = "CANCEL_ORDERS"
    /\ orders' = {}
    /\ phase' = "NET_HEDGE"
    /\ UNCHANGED
       <<marginRatio, positions, isolated,
         accountEquity, transferredToBackstop>>

NetHedge ==
    /\ phase = "NET_HEDGE"
    /\ positions' = positions
    /\ phase' = "REDUCE_IOC"
    /\ UNCHANGED
       <<marginRatio, orders, isolated,
         accountEquity, transferredToBackstop>>

ReduceIOC ==
    /\ phase = "REDUCE_IOC"
    /\ \/ /\ marginRatio' \in 101..200
          /\ phase' = "HEALTHY"
          /\ UNCHANGED
             <<positions, orders, isolated,
               accountEquity, transferredToBackstop>>
       \/ /\ marginRatio' \in 0..100
          /\ phase' = "TAKEOVER"
          /\ UNCHANGED
             <<positions, orders, isolated,
               accountEquity, transferredToBackstop>>

Takeover ==
    /\ phase = "TAKEOVER"
    /\ \/ /\ marginRatio <= TakeoverThreshold
          /\ phase' = "BACKSTOP"
          /\ UNCHANGED
             <<marginRatio, positions, orders, isolated,
               accountEquity, transferredToBackstop>>
       \/ /\ marginRatio > TakeoverThreshold
          /\ phase' = "REDUCE_IOC"
          /\ UNCHANGED
             <<marginRatio, positions, orders, isolated,
               accountEquity, transferredToBackstop>>

Backstop ==
    /\ phase = "BACKSTOP"
    /\ transferredToBackstop' = TRUE
    /\ positions' = {}
    /\ phase' = "TERMINATED"
    /\ UNCHANGED
       <<marginRatio, orders, isolated, accountEquity>>

StayHealthy ==
    /\ phase = "HEALTHY"
    /\ UNCHANGED vars

StayTerminated ==
    /\ phase = "TERMINATED"
    /\ UNCHANGED vars

Next ==
    \/ Eval
    \/ CancelOrders
    \/ NetHedge
    \/ ReduceIOC
    \/ Takeover
    \/ Backstop
    \/ StayHealthy
    \/ StayTerminated

Spec ==
    Init /\ [][Next]_vars

====

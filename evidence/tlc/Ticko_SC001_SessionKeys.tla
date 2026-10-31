---- MODULE Ticko_SC001_SessionKeys ----
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS
    Accounts,
    Permissions,
    Nonces,
    NoNonce,
    OwnerAccount,
    InitialPermissions

VARIABLES
    owner,
    grantedPerms,
    usedNonces,
    acceptedNonces,
    expired,
    lastOp,
    lastNonce,
    targetAccount,
    verdict

vars ==
    <<owner, grantedPerms, usedNonces, acceptedNonces,
      expired, lastOp, lastNonce, targetAccount, verdict>>

SeqToSet(s) ==
    {s[i] : i \in 1..Len(s)}

Operations == {"ORDER", "WITHDRAW", "READ"}

RequiredPermission(op) ==
    CASE
        op = "ORDER"   -> "order"
      [] op = "WITHDRAW" -> "withdraw"
      [] op = "READ"    -> "read"

TypeOK ==
    /\ owner \in Accounts
    /\ grantedPerms \subseteq Permissions
    /\ usedNonces \subseteq Nonces
    /\ acceptedNonces \in Seq(Nonces)
    /\ expired \in BOOLEAN
    /\ lastOp \in Operations \cup {"NONE"}
    /\ lastNonce \in Nonces \cup {NoNonce}
    /\ targetAccount \in Accounts
    /\ verdict \in {"NONE", "ACCEPT", "REJECT"}

Init ==
    /\ owner = OwnerAccount
    /\ grantedPerms = InitialPermissions
    /\ usedNonces = {}
    /\ acceptedNonces = <<>>
    /\ expired = FALSE
    /\ lastOp = "NONE"
    /\ lastNonce = NoNonce
    /\ targetAccount = OwnerAccount
    /\ verdict = "NONE"

Attempt(op, nonce, target) ==
    /\ op \in Operations
    /\ nonce \in Nonces
    /\ target \in Accounts
    /\ IF
          ~expired
          /\ target = owner
          /\ nonce \notin usedNonces
          /\ RequiredPermission(op) \in grantedPerms
       THEN
          /\ verdict' = "ACCEPT"
          /\ usedNonces' = usedNonces \cup {nonce}
          /\ acceptedNonces' = Append(acceptedNonces, nonce)
       ELSE
          /\ verdict' = "REJECT"
          /\ usedNonces' = usedNonces
          /\ acceptedNonces' = acceptedNonces
    /\ lastOp' = op
    /\ lastNonce' = nonce
    /\ targetAccount' = target
    /\ UNCHANGED <<owner, grantedPerms, expired>>

ExpireSession ==
    /\ expired = FALSE
    /\ expired' = TRUE
    /\ verdict' = "NONE"
    /\ lastOp' = "NONE"
    /\ lastNonce' = NoNonce
    /\ targetAccount' = owner
    /\ UNCHANGED
       <<owner, grantedPerms, usedNonces, acceptedNonces>>

Next ==
    \/ \E op \in Operations,
          nonce \in Nonces,
          target \in Accounts :
          Attempt(op, nonce, target)
    \/ ExpireSession

Spec ==
    Init /\ [][Next]_vars

AUTH001 ==
    verdict = "ACCEPT"
    => (lastOp # "ORDER" \/ "order" \in grantedPerms)

AUTH002 ==
    verdict = "ACCEPT"
    => (lastOp # "WITHDRAW" \/ "withdraw" \in grantedPerms)

AUTH003 ==
    /\ usedNonces = SeqToSet(acceptedNonces)
    /\ Cardinality(SeqToSet(acceptedNonces))
       = Len(acceptedNonces)

AUTH004 ==
    verdict = "ACCEPT"
    => targetAccount = owner

AUTH005 ==
    verdict = "ACCEPT"
    => expired = FALSE

AuthInv ==
    /\ TypeOK
    /\ AUTH001
    /\ AUTH002
    /\ AUTH003
    /\ AUTH004
    /\ AUTH005

====

# ambrus-e4c

## Overview

This repository contains the smart contracts for the Ambrus $E4C token.

Modules high level description:

- E4C Module: Handles the creation and minting of E4C tokens.
- Staking Module: Handles staking of E4C tokens for veE4C, including reward calculations.
- Exchange Module: Handles the exchange of E4C tokens
- Config Module: Handles the configuration of the staking pool

```mermaid
graph TB
    subgraph Smart Contract
        subgraph E4C Module
            TC[TreasuryCap]
            E4CM[Metadata]
            E4C[$E4C]
            I[[Inventory]]
        end
        subgraph Vesting Module
            VP[VestingPool]
        end
        subgraph Staking Module
            SP[StakingPool]
        end
        subgraph Exchange Module
            PR[PayoutReceipt]
            EP[ExchangePool]
        end
        subgraph Config Module
            SC[StakingConfig]
            EC[ExchangeConfig]
        end
    end

    subgraph Game
        AG[ArenaGem]
        TR[TicketRoom]
    end

    subgraph Game
        AG[Arena Gem]
    end

    subgraph Actors
        U[Users]
        S[Shareholders]
        A[Admin]
    end

%% Package Publishing 
    A -- Publish Package --> TC -- Mint --> E4C -- All in --> I
    TC -- Freeze --> E4CM
    TC -- Burn --> TC
%% Vesting
    I -- Inject --> VP
    S -- Claim --> VP
    VP -- Release --> S
%% Exchange
    U -- Hold --> AG
    AG <-- Exchangeable --> I
    I -- Exchange AGem for $E4C --> EP
    EP -- Wait for 10 days --> EP
    EP -- Release 100 $E4C <br>per day --> U
    EP -- Release staked <br>amount of $E4C --> U
%% Staking  && Unstaking
    U -- Stake $E4C --> SP
    I -- Inject Reward --> SP
    SP -- Wait for <br>staking period --> SP
    SP -- Unstake $E4C --> U
```

## Sequence Diagram

### Publish Package and Mint $E4C

The following sequence diagram illustrates the process of publishing a package and minting the E4C token.

```mermaid
sequenceDiagram
    actor A as Ambrus
    Note over A: Ambrus account could be a multisig wallet
    participant e4c as e4c package
    A ->> e4c: publish package
    e4c ->> e4c: create $E4C
    e4c ->> e4c: mint all $E4C and transfer to inventory
    e4c ->> e4c: freeze metadata and treasury
    e4c ->> A: transfer InventoryCap
```

### Withdraw $E4C

The following sequence diagram illustrates the process of withdrawing $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant e4c
    participant exchange
    participant staking
    U ->> exchange: request to withdraw $E4C
    exchange ->> e4c: take $E4C from inventory
    e4c ->> staking: lockup $E4C
    staking -->> staking: 10 days lockup
    Note over staking: staking $E4C token can shorten the locking period
    alt is user staking
        staking ->> U: transfer the staked amount of $E4C in locked state immediately
    end
    U ->> exchange: request to unlock $E4C
    exchange ->> staking: unlock $E4C
    staking ->> exchange: release $E4C
    exchange ->> U: withdraw $E4C
    Note over U: Maximum withdrawal amount is 100 $E4C per day
```

### Stake and Unstake $E4C

The following sequence diagram illustrates the process of staking and unstaking $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant e4c
    participant staking
    participant config
    U ->> staking: request to stake $E4C
    staking ->> staking: create a new staking pool
    staking ->> config: get staking pool configuration
    config ->> staking: return staking rate and expected reward
    staking ->> e4c: claim $E4C reward from inventory
    e4c ->> staking: inject $E4C reward to staking pool
    staking -->> staking: wait for staking days
    U ->> staking: request to unstake $E4C
    staking ->> U: transfer staked and reward $E4C
    alt optional
        U ->> staking: destroy empty staking pool
        staking ->> U: get storage rebate
    end
```

### Pay $E4C

The following sequence diagram illustrates the process of paying $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant e4c
    participant exchange
    U ->> exchange: pay $E4C with action name
    exchange ->> e4c: transfer $E4C to inventory
    e4c ->> exchange: issue PaymentReceipt
    Note over exchange: The receipt can be used to exchange for on-chain assets in the future
    exchange ->> exchange: Emit Payed event
    Note over exchange: The event can be used to track the payment history in web2
```

### Configure Staking Pool

The following sequence diagram illustrates the process of configuring the staking pool.

```mermaid
sequenceDiagram
    actor A as Ambrus
    participant config
    A ->> config: add/remove configure staking pool
    config ->> config: set staking pool configuration
    Note over config: The update does not affect existing staking pool
```

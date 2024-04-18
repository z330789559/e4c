# ambrus-e4c

## Overview

This repository contains the smart contracts for the Ambrus $E4C token.

Modules high level description:

- E4C Module: Handles the creation and minting of E4C tokens.
- Staking Module: Handles staking of E4C tokens for veE4C, including reward calculations.
- Config Module: Handles the configuration of the staking pool

## Sequence Diagram

### Publish Package and Mint $E4C

The following sequence diagram illustrates the process of publishing a package and minting the E4C token.

```mermaid
sequenceDiagram
    actor A as Ambrus
    actor M as MSage
    participant e4c as e4c
    participant staking as staking
    participant config as config
    A ->> e4c: publish package
    e4c --> e4c: initialize e4c module
    e4c --> staking: initialize staking module
    e4c --> config: initialize config module
    e4c ->> e4c: create $E4C and <br />GameLiquidityPool and <br />AdminCap
    e4c ->> e4c: mint all $E4C
    e4c ->> e4c: freeze metadata and <br />burn treasury
    e4c ->> e4c: transfer $E4C to <br />GameLiquidityPool
    e4c ->> M: transfer $E4C
    e4c ->> A: transfer AdminCap
    config ->> config: share staking pool configuration
    config ->> config: setup pre-defined staking rule
```

### Stake and Unstake $E4C

The following sequence diagram illustrates the process of staking $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant e4c
    participant staking
    participant config
    U ->> staking: request to stake $E4C
    staking ->> staking: create a new StakingPool
    staking ->> config: get StakingRule
    config ->> staking: return staking rate and expected reward
    staking ->> e4c: claim $E4C reward from GameLiquidityPool
    e4c ->> staking: inject $E4C reward to StakingPool
    staking ->> U: transfer the StakingPool
```

### Unstake and Claim Reward

The following sequence diagram illustrates the process of unstaking $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant e4c
    participant staking
    participant config
    U ->> staking: request to unstake $E4C from StakingPool
    staking ->> staking: validate unstaking request
    staking ->> U: transfer staked and reward $E4C
    alt optional
        U ->> staking: destroy empty StakingPool
        staking ->> U: get storage rebate
    end
```

### Configure Staking Pool

The following sequence diagram illustrates the process of configuring the staking pool.

```mermaid
sequenceDiagram
    actor A as Ambrus
    participant config
    A ->> config: add/remove configure staking pool
    config ->> config: set staking pool configuration
    Note over config: The update does not affect on existing StakingPool
```

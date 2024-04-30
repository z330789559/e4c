# ambrus-e4c

## Overview

This repository contains the smart contracts for the Ambrus $E4C token.

Modules high level description:

- E4C Package: Handles the creation and minting of E4C tokens.
    - E4C Module: Handles the creation and minting of E4C tokens.
- E4C Staking Package: Handles the staking of E4C tokens.
    - Staking Module: Handles staking of E4C tokens for veE4C, including reward injection.
    - Config Module: Handles the configuration of the staking pool.

## Sequence Diagram

### Publish e4c Package and mint $E4C

The following sequence diagram illustrates the process of publishing a package and minting the E4C token.

```mermaid
sequenceDiagram
    actor A as Admin
    participant e4c as e4c
    A ->> e4c: publish package
    box White e4c package
        participant e4c as e4c
    end
    e4c ->> e4c: mint all $E4C
    e4c ->> e4c: freeze metadata and <br />burn treasury
    e4c ->> e4c: create and freeze E4CTotalSupply
    e4c ->> A: transfer all $E4C
```

### Publish e4c_staking package

The following sequence diagram illustrates the process of publishing a package for the staking module.

Make sure to publish the e4c package first and add the e4c_package dependency
to [./e4c_staking/Move.toml](e4c_staking/Move.toml).

```mermaid
sequenceDiagram
    actor A as Admin
    participant staking as staking
    participant config as config
    A ->> staking: publish package
    box Gray e4c_staking package
        participant staking as staking
        participant config as config
    end
    staking ->> staking: create and share <br />GameLiquidityPool
    staking ->> staking: create AdminCap
    config ->> config: create and share <br />StakingConfig
    config ->> config: setup pre-defined staking rule
```

### Distribute $E4C

The following sequence diagram illustrates the process of distributing the E4C token to shareholders.

```mermaid
sequenceDiagram
    actor A as Admin
    actor M as MSafe
    actor C as CEX
    participant staking as staking
    Note over A: w/$E4C
    A ->> M: transfer $E4C to MSafe
    A ->> C: transfer $E4C to CEX
    A ->> staking: put $E4C to GameLiquidityPool
```

### Stake $E4C

The following sequence diagram illustrates the process of staking $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant staking
    participant config
    U ->> staking: request to stake $E4C
    staking ->> staking: create a new StakingReceipt
    staking ->> config: get StakingRule
    config ->> staking: return staking rate and <br />expected reward
    staking ->> staking: inject $E4C reward <br />from GameLiquidityPool <br />to StakingReceipt
    staking ->> U: transfer the StakingReceipt
```

### Unstake and Claim Reward

The following sequence diagram illustrates the process of unstaking $E4C token.

```mermaid
sequenceDiagram
    actor U as User
    participant staking
    participant config
    Note over U: w/StakingReceipt
    U ->> staking: request to unstake $E4C from StakingReceipt
    staking ->> staking: validate unstaking request
    staking ->> U: transfer staked and reward $E4C
```

### Configure Staking Rules

The following sequence diagram illustrates the process of configuring the staking pool.

```mermaid
sequenceDiagram
    actor A as Admin
    participant C as config
    Note over A: w/AdminCap
    A ->> C: add/remove StakingConfig
    C ->> C: set new staking configuration
```

## Deployment Instructions

### 1. Prepare you Sui account

1.1 Verifying Sui Installation

Check that Sui is installed successfully on your system:

    sui --version

1.2 Configuring Sui for Testnet/Mainnet

Configure the Sui client to use the testnet/mainnet RPC:

    sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443

1.3 Switching to the desired Environment

Change your Sui client to the testnet/mainnet environment:

    sui client switch --env testnet
    sui client active-env

1.4 Creating a New Sui Address with your keypair

Create a new account and save the recoveryPhrase for later use:

    sui client new-address ed25519

1.5 Switch to you new Address

Make your active address to be the newly created:

    sui client switch --address {alias}

1.6 Verify your Sui token balance:

    sui client gas

### 2. Deploy Your Smart Contracts on Testnet/Mainnet

2.1 Preparing the Publish Script

Navigate to the /setup directory and grant execute permissions to the publish_e4c.sh and publish_e4c_staking.sh scripts:

    chmod +x publish_e4c.sh
    chmod +x publish_e4c_staking.sh

2.2 Installing Dependencies

Install necessary library dependencies:

    npm install

2.3 Deploying Contracts

Deploy your contracts to testnet to populate the .env and .env.staking files in the setup/src folder:

    ./publish_e4c.sh testnet
    ./publish_e4c_staking.sh testnet

### 3. Test Move Call functions by using Typescript calls

3.1 Configure the .env and .env.staking Files according to the template `.template` files

Open the `src/.env` file and fill in the `ADMIN_MNEMOMIC_PHRASE` with the recoveryPhrase from your Sui account creation and the `src/.env.staking` file with a `PLAYER_MNEMOMIC_PHRASE` to test transactions signed by a player.

3.2 Run Typesctipt code to invoke your module functions

       ts-node moveCalls.ts {command}

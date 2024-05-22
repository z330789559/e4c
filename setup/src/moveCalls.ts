// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { SuiClient } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";

import {
    E4C_PACKAGE, // The package ID of the E4C coin
    STAKING_PACKAGE, // The package ID of the Staking
    SUI_NETWORK, // The URL of the Sui network
    ADMIN_PHRASE, // Mnemonic phrase managed by Ambrus to sign transactions
    PLAYER_PHRASE, // Mnemonic phrase managed by a Player to sign transactions
    GAME_LIQIUIDITY_POOL, // The address of the GamingLiquitidyPool shared object
    STAKING_CONFIG // The ID of the StakingConfig shared object
  } from "./config";

// Create a client to connect to the Sui network
const getClient = () => {
  console.log("Connecting to ", SUI_NETWORK);
    let client = new SuiClient({
    url: SUI_NETWORK,
    });

  return client;
};

// Derive the keypair from the Mnemonic phrase to sign transactions
const getSigner = (signer: string) => {
  // derive keypair from the Mnemonic phrase
  const keypair = Ed25519Keypair.deriveKeypair(signer);
  return keypair;
};

// Instantiate the client
const client = getClient();

// Constants
const COIN_SIZE = 10_000; // The size of a splitted E4C coin
const E4C_COIN_TYPE = `0x2::coin::Coin<${E4C_PACKAGE}::e4c::E4C>`;

// Derive addresses from the Mnemonic phrases
console.log("ADMIN_PHRASE", PLAYER_PHRASE);
let adminAddress = getSigner(ADMIN_PHRASE).getPublicKey().toSuiAddress();
let playerAddress = getSigner(PLAYER_PHRASE).getPublicKey().toSuiAddress();

//---------------------------------------------------------
/// Split E4C coins
//---------------------------------------------------------
const splitCoins = async (numberOfCoins: number = 5) => {

    let tx = new TransactionBlock();
    // example of how to read from an address
    const userObjects = await client.getOwnedObjects({
        owner: adminAddress,
        options: {
        showContent: true,
        showType: true,
        },
    });

    // getting all objects of type E4C 
    const E4CObjects = userObjects?.data?.filter((elem: any) => {
        return elem?.data?.type === E4C_COIN_TYPE && elem?.data.content?.amount >= COIN_SIZE;
    });

    // get the first E4C coin
    const e4cCoin = E4CObjects[0].data?.objectId as string;
  
    for (let i = 0; i < numberOfCoins; i++) {
      let coin = tx.splitCoins(e4cCoin, [tx.pure(COIN_SIZE)]);
      // transfer the splitted coins to the admin address handled by Ambrus
      tx.transferObjects([coin], tx.pure(adminAddress));
    }
    // sign and execute the transaction block
    let res = await client.signAndExecuteTransactionBlock({
      transactionBlock: tx,
      requestType: "WaitForLocalExecution",
      signer: getSigner(ADMIN_PHRASE),
      options: {
        showEffects: true,
        },
    });
    console.log(res);
  };

//---------------------------------------------------------
/// Top-up the GamingPool with E4C coins
//---------------------------------------------------------
const topUpGamingPool = async () => {

    let tx = new TransactionBlock();
console.log(adminAddress)
    // Get all objects owned by the admin address
    const userObjects = await client.getOwnedObjects({
        owner: adminAddress,
        options: {
        showContent: true,
        showType: true,
        },
    });

   
    // Filter the E4C coins
    const E4CObjects = userObjects?.data?.filter((elem: any) => {
        return elem?.data?.type === E4C_COIN_TYPE && elem?.data?.content?.fields?.balance >= 200;
    });
    console.log(JSON.stringify(E4CObjects));
    const e4cCoin = E4CObjects[0].data?.objectId as string;

    tx.moveCall({
      target: `${STAKING_PACKAGE}::staking::place_in_pool`,
      arguments: [
        tx.object(GAME_LIQIUIDITY_POOL),
        tx.object(e4cCoin)
        ],
    });
    try {
        let txRes = await client.signAndExecuteTransactionBlock({
          transactionBlock: tx,
          requestType: "WaitForLocalExecution",
          signer: getSigner(ADMIN_PHRASE),
          options: {
            showEffects: true,
            },
        });
    
        console.log(txRes);
      } catch (e) {
        console.error("Could not place $e4c in pool", e);
      }
  };

//---------------------------------------------------------
/// Transfer E4C coins to the Player address
//---------------------------------------------------------  
const transferE4CToPlayer = async () => {

    let tx = new TransactionBlock();
    
    // Get all objects owned by the admin address
    const userObjects = await client.getOwnedObjects({
        owner: adminAddress,
        options: {
        showContent: true,
        showType: true,
        },
    });

    // Filter the E4C coins
    const E4CObjects = userObjects?.data?.filter((elem: any) => {
        return elem?.data?.type === E4C_COIN_TYPE;
    });
    const e4cCoin = E4CObjects[0].data?.objectId as string;

    // Transfer the E4C coin to the player address
    tx.transferObjects([e4cCoin], tx.pure(playerAddress));
  
    let res = await client.signAndExecuteTransactionBlock({
      transactionBlock: tx,
      requestType: "WaitForLocalExecution",
      signer: getSigner(ADMIN_PHRASE),
      options: {
        showEffects: true,
        },
    });
    console.log(res);
  };

//---------------------------------------------------------
/// Stake E4C coins
//---------------------------------------------------------  
const stake = async () => {
    
    let tx = new TransactionBlock();

    // example of how to read an address
    const userObjects = await client.getOwnedObjects({
        owner: playerAddress,
        options: {
        showContent: true,
        showType: true,
        },
    });

    const e4cObjects = userObjects?.data?.filter((elem: any) => {
        return elem?.data?.type === E4C_COIN_TYPE;
    });

    // This coin will be provided by the user to stake
    let e4cCoin = e4cObjects[0].data?.objectId as string;

    let stakingReceipt = tx.moveCall({
        target: `${STAKING_PACKAGE}::staking::new_staking_receipt`,
        arguments: [
            tx.object(e4cCoin), // The E4C coin object to stake
            tx.object(GAME_LIQIUIDITY_POOL),
            tx.object(SUI_CLOCK_OBJECT_ID),
            tx.object(STAKING_CONFIG),
            tx.pure("90", "u64"), // 90 days
            ],
        });
    
        // Transfer the E4C coin to the player address
    tx.transferObjects([stakingReceipt], tx.pure(playerAddress));

    tx.setGasBudget(1000000000);

    try {
        let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer: getSigner(PLAYER_PHRASE),
        options: {
            showEffects: true,
            },
        });
        console.log(txRes);
    } catch (e) {
        console.error("Could not stake $e4c in pool", e);
    }
};

//---------------------------------------------------------
/// Unstake and claim rewards
//--------------------------------------------------------- 
const unstake = async (staking_receipt: string) => {
    
    let tx = new TransactionBlock();

    let [rewards] = tx.moveCall({
        target: `${STAKING_PACKAGE}::staking::unstake`,
        arguments: [
            tx.object(staking_receipt),
            tx.object(SUI_CLOCK_OBJECT_ID),
        ],
        });

    tx.transferObjects([rewards], tx.pure(playerAddress));

    tx.setGasBudget(1000000000);

    try {
        let txRes = await client.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        requestType: "WaitForLocalExecution",
        signer: getSigner(PLAYER_PHRASE),
        options: {
            showEffects: true,
            },
        });
        console.log(txRes);
    } catch (e) {
        console.error("Could not receive rewards", e);
    }
};

//---------------------------------------------------------
/// Entry point to run the functions
//--------------------------------------------------------- 
if (process.argv[2] === undefined) {
    console.log("Please provide a command");
  } else {
    const command = process.argv[2];
    switch (command) {
        case "splitCoins":
            splitCoins();
            break;
        case "topUpGamingPool":
            topUpGamingPool();
            break;
        case "transferE4CToPlayer":
            transferE4CToPlayer();
            break;
        case "stake":
            stake();
            break;
        case "unstake":
            // Provide the staking receipt as an argument
            unstake("");
            break;    
      }
    }



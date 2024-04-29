// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module e4c::e4c {
    use sui::{
        coin::{Self},
        balance
    };

    // === Constants ===
    const E4CTokenMaxSupply: u64 = 1_000_000_000;
    // TODO: update the token metadata according to the requirements.
    const E4CTokenDecimals: u8 = 6;
    const E4CTokenSymbol: vector<u8> = b"E4C";
    const E4CTokenName: vector<u8> = b"$E4C";
    const E4CTokenDescription: vector<u8> = b"$E4C is ...";

     // [frozen Object] E4CFunded is a struct that holds the total supply of the E4C token.
    public struct E4CTotalSupply has key {
        id: UID,
        total_supply: balance::Supply<E4C>
    }

    // [One Time Witness] E4C is a one-time witness struct that is used to initialize the E4C token.
    public struct E4C has drop {}

    fun init(otw: E4C, ctx: &mut TxContext) {
        // Create a regulated currency with the given metadata.
        let (mut treasuryCap, deny_cap, metadata) = coin::create_regulated_currency(
            otw,
            E4CTokenDecimals,
            E4CTokenSymbol,
            E4CTokenName,
            E4CTokenDescription,
            option::none(),
            ctx
        );
        // Mint the coin and get the coin object.
        let coin = coin::mint(&mut treasuryCap, E4CTokenMaxSupply, ctx);
        // Unwrap and burn the treasury cap and get the total supply.
        let total_supply = treasuryCap.treasury_into_supply();

        // Freeze the metadata and total supply object.
        transfer::public_freeze_object(metadata);
        transfer::freeze_object(E4CTotalSupply { id: object::new(ctx), total_supply });
        
        // Send the deny cap to the sender.
        transfer::public_transfer(deny_cap, ctx.sender());
        // Send the total supply; 1B to the sender.
        transfer::public_transfer(coin, ctx.sender());

    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }

    #[test_only]
    public fun get_total_supply(meta: &E4CTotalSupply): u64 {
        balance::supply_value(&meta.total_supply)
    }
}
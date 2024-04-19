module e4c::e4c {
    use std::option;

    use sui::balance::Supply;
    use sui::coin::Self;
    use sui::object;
    use sui::object::UID;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    // === Constants ===
    // TODO: update the token metadata according to the requirements.
    const E4CTokenMaxSupply: u64 = 1_000_000_000;
    const E4CTokenDecimals: u8 = 6;
    const E4CTokenSymbol: vector<u8> = b"E4C";
    const E4CTokenName: vector<u8> = b"$E4C";
    const E4CTokenDescription: vector<u8> = b"$E4C is ...";

    // === Structs ===

    // [One Time Witness] E4C is a one-time witness struct that is used to initialize the E4C token.
    struct E4C has drop {}

    // [frozen Object] E4CFunded is a struct that holds the total supply of the E4C token.
    struct E4CTotalSupply has key {
        id: UID,
        total_supply: Supply<E4C>
    }

    fun init(otw: E4C, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            otw,
            E4CTokenDecimals,
            E4CTokenSymbol,
            E4CTokenName,
            E4CTokenDescription,
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);

        // Mint all the tokens to the GameLiquidityPool
        let coin = coin::mint(&mut treasury, E4CTokenMaxSupply, ctx);
        // Burn the TreasuryCap to prevent further minting and burning.
        let total_supply = coin::treasury_into_supply(treasury);

        // Freeze the total supply object.
        transfer::freeze_object(E4CTotalSupply { id: object::new(ctx), total_supply });
        transfer::public_transfer(coin, sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }
}

module e4c::e4c {
    use std::option;

    use sui::balance::{Self, Balance, Supply};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    friend e4c::staking;
    friend e4c::exchange;

    // === Errors ===
    // Error code for when the amount is too low.
    const EAmountMustBeGreaterThanZero: u64 = 1;
    const EAmountTooHigh: u64 = 2;

    // === Constants ===
    // The maximum supply of E4C tokens.
    const E4CTokenMaxSupply: u64 = 1_000_000_000;


    // === Structs ===

    struct E4C has drop {}

    // [Owned Object]: InventoryCap is a cap for the E4C tokens.
    struct InventoryCap has key, store {
        id: UID,
    }

    // [Shared Object]: Inventory is a store of minted E4C tokens.
    struct Inventory has key, store {
        id: UID,
        balance: Balance<E4C>,
        total_supply: Supply<E4C>
    }

    fun init(witness: E4C, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            // TODO: Need to update the metadata according to the actual requirements.
            6,
            b"E4C",
            b"E4C Token",
            b"E4C Token is ...",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);

        // Mint all the tokens to the Inventory and burn the TreasuryCap to prevent further minting and burning.
        let coin = coin::mint(&mut treasury, E4CTokenMaxSupply, ctx);
        let total_supply = coin::treasury_into_supply(treasury);

        transfer::public_transfer(InventoryCap { id: object::new(ctx) }, sender(ctx));
        transfer::public_share_object(
            Inventory { id: object::new(ctx), balance: coin::into_balance(coin), total_supply }
        );
    }

    // public fun take(_: &InventoryCap, inventory: &mut Inventory, amount: u64, ctx: &mut TxContext): Coin<E4C> {
    //     assert!(amount > 0, EAmountMustBeGreterThanZero);
    //     assert!(amount <= balance::value(&inventory.balance), EAmountTooHigh);
    //
    //     let coin = coin::take(&mut inventory.balance, amount, ctx);
    //     coin
    // }

    // Take E4C tokens from the Inventory without capability check.
    // This function is only accessible to the friend module.
    public(friend) fun take_by_friend(inventory: &mut Inventory, amount: u64, ctx: &mut TxContext): Coin<E4C> {
        assert!(amount > 0, EAmountMustBeGreaterThanZero);
        assert!(amount <= balance::value(&inventory.balance), EAmountTooHigh);

        let coin = coin::take(&mut inventory.balance, amount, ctx);
        coin
    }

    // Put back E4C tokens to the Inventory without capability check.
    // This function can be called by anyone.
    public fun put_back(inventory: &mut Inventory, coin: Coin<E4C>, ctx: &mut TxContext) {
        assert!(coin::value(&coin) > 0, EAmountMustBeGreaterThanZero);
        balance::join(&mut inventory.balance, coin::into_balance(coin));
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }
}

module e4c::treasury {
    use sui::{
        coin::{Self, TreasuryCap, Coin},
        dynamic_object_field::{Self as dof}
    };

    public struct TreasuryCapKey has copy, store, drop {}

    public struct ControlledTreasury<phantom T> has key {
        id: UID,
        minted: u64,
        mint_limit: u64,
        key: ID
    }

    public struct ControlledTreasuryCap has key, store {
        id: UID
    }

    public fun new<T>(treasury_cap: TreasuryCap<T>, mint_limit: u64, ctx: &mut TxContext): ControlledTreasuryCap {
        let cap = ControlledTreasuryCap {
            id: object::new(ctx)
        };

        let mut treasury = ControlledTreasury<T> {
            id: object::new(ctx),
            minted: 0,
            key: object::id(&cap),
            mint_limit
        };

        dof::add(&mut treasury.id, TreasuryCapKey {}, treasury_cap);

        transfer::share_object(treasury);

        cap
    }

    public fun mint<T>(treasury: &mut ControlledTreasury<T>, cap: &ControlledTreasuryCap, amount: u64, ctx: &mut TxContext): Coin<T> {
        assert!(treasury.key == object::id(cap), 0);
        assert!(treasury.minted + amount <= treasury.mint_limit, 1);

        treasury.minted = treasury.minted + amount;

        coin::mint(treasury.treasury_cap_mut(), amount, ctx)
    }

    public fun burn<T>(treasury: &mut ControlledTreasury<T>, cap: &ControlledTreasuryCap, coin: Coin<T>) {
        assert!(treasury.key == object::id(cap), 0);
        coin::burn(treasury.treasury_cap_mut(), coin);
    }

    fun treasury_cap_mut<T>(treasury: &mut ControlledTreasury<T>): &mut TreasuryCap<T> {
        dof::borrow_mut(&mut treasury.id, TreasuryCapKey {})
    }
}
module e4c::treasury {
    use sui::{
        coin::{Self, TreasuryCap, Coin},
        dynamic_object_field::{Self as dof},
        event::{Self},
    };

    // === Errors ==

    const EExceedMintingLimit: u64 = 0; 
    const ETreasuryKeyIsNotMatched: u64 = 1;

    /// === DF Keys ===

    public struct TreasuryCapKey has copy, store, drop {}

    /// === Objects ===

    public struct ControlledTreasury<phantom T> has key {
        id: UID,
        minted: u64,
        mint_limit: u64,
        key: ID
    }

    public struct ControlledTreasuryCap has key, store {
        id: UID
    }

    // === Events ===

    public struct MintEvent<phantom T> has copy, drop { amount: u64 }

    // === Public-Mutative Functions ===

    public fun new<T>(treasury_cap: TreasuryCap<T>, mint_limit: u64, ctx: &mut TxContext): ControlledTreasuryCap {
        let cap = ControlledTreasuryCap {
            id: object::new(ctx)
        };
        let mut treasury = ControlledTreasury<T> {
            id: object::new(ctx),
            minted: 0,
            mint_limit,
            key: object::id(&cap),
        };
        dof::add(&mut treasury.id, TreasuryCapKey {}, treasury_cap);
        transfer::share_object(treasury);
        cap
    }

    public fun mint<T>(treasury: &mut ControlledTreasury<T>, cap: &ControlledTreasuryCap, amount: u64, ctx: &mut TxContext): Coin<T> {
        assert!(treasury.key == object::id(cap), ETreasuryKeyIsNotMatched);
        assert!(treasury.minted + amount <= treasury.mint_limit, EExceedMintingLimit);

        event::emit(MintEvent<T> { amount });
        treasury.minted = treasury.minted + amount;
        coin::mint(treasury.treasury_cap_mut(), amount, ctx)
    }

    // === Private Functions ===

    fun treasury_cap_mut<T>(treasury: &mut ControlledTreasury<T>): &mut TreasuryCap<T> {
        dof::borrow_mut(&mut treasury.id, TreasuryCapKey {})
    }

    // ==== Public view function ====
    public fun controlled_treasury_minted<T>(treasury: &ControlledTreasury<T>): u64 {
        treasury.minted
    }

    public fun controlled_treasury_mint_limit<T>(treasury: &ControlledTreasury<T>): u64 {
        treasury.mint_limit
    }
}

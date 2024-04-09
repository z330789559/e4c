module e4c::e4c {
    use std::option;
    
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};
    
    struct E4C has drop {}
    
    fun init(witness: E4C, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"E4C",
            b"E4C Token",
            b"E4C Token is ...",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, sender(ctx));
    }
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }
}

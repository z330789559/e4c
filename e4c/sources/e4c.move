module e4c::e4c {
    use sui::coin::Self;
    use sui::tx_context::{sender};

    // === Constants ===
    // TODO: update the token metadata according to the requirements.
    const E4CTokenDecimals: u8 = 6;
    const E4CTokenSymbol: vector<u8> = b"E4C";
    const E4CTokenName: vector<u8> = b"$E4C";
    const E4CTokenDescription: vector<u8> = b"$E4C is ...";

    // === Structs ===

    // [One Time Witness] E4C is a one-time witness struct that is used to initialize the E4C token.
    public struct E4C has drop {}

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
        transfer::public_transfer(treasury, sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }
}

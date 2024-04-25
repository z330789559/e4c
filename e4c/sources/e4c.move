module e4c::e4c {
    use sui::coin::{Self, DenyCap};
    use sui::deny_list::{DenyList};

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
        let (treasury, deny_cap, metadata) = coin::create_regulated_currency(
            otw,
            E4CTokenDecimals,
            E4CTokenSymbol,
            E4CTokenName,
            E4CTokenDescription,
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender());
        transfer::public_transfer(deny_cap, ctx.sender());
    }

    public fun add_addr_to_deny_list(denylist: &mut DenyList, denycap: &mut DenyCap<E4C>, denyaddr: address, ctx: &mut TxContext) {
        coin::deny_list_add(denylist, denycap, denyaddr, ctx);
    }

    public fun remove_addr_from_deny_list(denylist: &mut DenyList, denycap: &mut DenyCap<E4C>, denyaddr: address, ctx: &mut TxContext) {
        coin::deny_list_remove(denylist, denycap, denyaddr, ctx);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(E4C {}, ctx); }
}

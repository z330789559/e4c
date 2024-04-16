module e4c::payment {

    use std::string::String;

    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::tx_context::{sender, TxContext};

    use e4c::e4c::{E4C, Inventory, put_back};

    // The event that will be triggered when a payment is made.
    struct Payed has drop, copy {
        amount: u64,
        payer: address,
        purpose: String
    }

    // TODO: This can be removed due to the conv that the responsibility should be taken by a marketplace
    //      which will handle the actual exchange of the receipt for on-chain assets.
    // The struct that will be used as a receipt for the payment.
    struct PaymentReceipt has drop {
        amount: u64,
        payer: address,
        purpose: String
    }

    public fun pay(
        inventory: &mut Inventory,
        payment: Coin<E4C>,
        purpose: String,
        ctx: &mut TxContext
    ): PaymentReceipt {
        let amount = coin::value(&payment);
        // The triggered event will be used to track the payment off-chain.
        event::emit(Payed {
            amount,
            payer: sender(ctx),
            purpose
        });

        put_back(inventory, payment);
        // In the future, we can use the receipt to exchange for on-chain assets.
        PaymentReceipt {
            amount,
            payer: sender(ctx),
            purpose
        }
    }
}

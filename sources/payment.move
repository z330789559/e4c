module e4c::payment {
    use sui::coin;
    use sui::coin::Coin;
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};
    
    use e4c::e4c::E4C;
    
    /// The event that will be triggered when a payment is made.
    struct Payed has drop, copy {
        amount: u64,
        payer: address,
    }
    
    /// The struct that will be used as a receipt for the payment.
    struct PaymentReceipt has drop {
        amount: u64,
        payer: address,
    }
    
    public fun pay(payment: Coin<E4C>, ctx: &mut TxContext): PaymentReceipt {
        let amount = coin::value(&payment);
        /// TODO: Need to make sure how to handle "use" of E4C token in the games.
        /// 1. Should we transfer the E4C token to Admin?
        /// 2. Should we transfer the E4C token to some treasury?
        /// 3. Should we burn the E4C token? 
        transfer::public_transfer(payment, @0x0); /// tmp solution to build the contract
        /// The triggered event will be used to track the payment off-chain.
        event::emit(Payed {
            amount,
            payer: sender(ctx),
        });
        /// In the future, we can use the receipt to use it as a proof of payment.
        PaymentReceipt {
            amount,
            payer: sender(ctx),
        }
    }
}

module e4c::payment {

    use std::string::String;

    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    use e4c::e4c::{E4C, Inventory};

    /// The event that will be triggered when a claim request is made.
    struct ClaimRequest has drop, copy {
        amount: u64,
        claimer: address,
        /// The purpose of the claim request.
        /// In web2, this field can be used to track the reason for the claim request.
        purpose: String
    }

    /// The event that will be triggered when a payment is made.
    struct Payed has drop, copy {
        amount: u64,
        payer: address,
        purpose: String
    }

    /// The struct that will be used as a receipt for the payment.
    struct PaymentReceipt has drop {
        amount: u64,
        payer: address,
        purpose: String
    }

    /// TODO: Need to implement the claim request functionality.
    /// Locking period will be 10 days and after that, the claimer can claim the E4C token.
    /// But the maximum withdrawal limit will be 100 E4C per days.
    /// The act of staking E4C token can shorten the locking period
    public fun request_claim(
        inventory: &mut Inventory,
        amount: u64,
        claimer: address,
        purpose: String,
        ctx: &mut TxContext
    ) {
        /// The claim request will be used to track the claim request off-chain.
        event::emit(ClaimRequest {
            amount,
            claimer,
            purpose
        });
    }

    public fun pay(payment: Coin<E4C>, purpose: String, ctx: &mut TxContext): PaymentReceipt {
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
            purpose
        });
        /// In the future, we can use the receipt to use it as a proof of payment.
        PaymentReceipt {
            amount,
            payer: sender(ctx),
            purpose
        }
    }
}

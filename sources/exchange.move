module e4c::exchange {

    use std::ascii;

    use sui::balance;
    use sui::balance::Balance;
    use sui::clock;
    use sui::clock::Clock;
    use sui::coin;
    use sui::coin::Coin;
    use sui::event;
    use sui::object;
    use sui::object::{ID, UID};
    use sui::token::action;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    use e4c::config::{exchange_lockup_period_in_days,
        exchange_ratio,
        ExchangeConfig,
        ExchangeDetail, get_exchange_detail
    };
    use e4c::e4c::{E4C, Inventory, take_by_friend};

    /// === Errors ===
    const ELockedAmountMustBeGreaterThanZero: u64 = 1;
    const EInvalidExchangePoolOwner: u64 = 2;
    const EExchangePoolLockupPeriodNotPassed: u64 = 3;

    /// [Shared Object]: ExchangePool is a shared object that represents the pool of locked tokens.
    /// The pool is created by the owner and the owner can lock the tokens in the pool.
    struct ExchangePool has key {
        id: UID,
        owner: address,
        amount_locked: u64,
        locked_at: u64,
        detail: ExchangeDetail,
        e4c_balance: Balance<E4C>,
    }

    struct ExchangePoolCreated has copy, drop {
        pool_id: ID,
        owner: address,
    }

    struct ExchangePoolUnlocked has copy, drop {
        pool_id: ID,
        owner: address,
        amount_unlocked: u64,
    }

    public fun new_exchange_pool(
        action: ascii::String,
        amount_locked: u64,
        clock: &Clock,
        config: &ExchangeConfig,
        inventory: &mut Inventory,
        ctx: &mut TxContext
    ) {
        assert!(amount_locked > 0, ELockedAmountMustBeGreaterThanZero);
        let detail = get_exchange_detail(config, action);
        let exchange_ratio = exchange_ratio(&detail);
        let exchange_balance = amount_locked * exchange_ratio;
        let e4c = take_by_friend(inventory, exchange_balance, ctx);
        let id = object::new(ctx);

        event::emit(ExchangePoolCreated {
            pool_id: object::uid_to_inner(&id),
            owner: sender(ctx),
        });

        transfer::share_object(ExchangePool {
            id,
            owner: sender(ctx),
            amount_locked,
            locked_at: clock::timestamp_ms(clock),
            detail,
            e4c_balance: coin::into_balance(e4c),
        })
    }

    public fun exchange_locup_end(pool: &ExchangePool): u64 {
        pool.locked_at + exchange_lockup_period_in_days(&pool.detail) * 24 * 60 * 60 * 1000
    }

    public fun unlock(pool: &mut ExchangePool, clock: &Clock, ctx: &mut TxContext): Coin<E4C> {
        assert!(pool.owner == sender(ctx), EInvalidExchangePoolOwner);
        assert!(exchange_locup_end(pool) <= clock::timestamp_ms(clock),
            EExchangePoolLockupPeriodNotPassed
        );
        let balance = balance::value(&pool.e4c_balance);
        event::emit(ExchangePoolUnlocked {
            pool_id: object::uid_to_inner(&pool.id),
            owner: pool.owner,
            amount_unlocked: balance,
        });
        coin::take(&mut pool.e4c_balance, balance, ctx)
    }

    /// TODO: add delete function
}

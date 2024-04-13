module e4c::exchange {

    use std::ascii;

    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::coin;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};
    use sui::vec_map::{Self, VecMap};

    use e4c::config::{calculate_locking_time,
        exchange_lockup_period_in_days,
        exchange_ratio, ExchangeConfig, ExchangeDetail, get_exchange_detail
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
        total_expected_e4c_amount: u64,
        exchanging_requests: VecMap<ID, ExchangeRequest>
    }

    /// [Owned object by ExchangePool]: ExchangeRequest is an owned object by ExchangePool.
    struct ExchangeRequest has key, store {
        id: UID,
        amount_locked: u64,
        locked_at: u64,
        detail: ExchangeDetail,
        locking_end_at: u64,
        e4c_balance: Balance<E4C>,
    }

    struct ExchangePoolCreated has copy, drop {
        pool_id: ID,
        owner: address,
    }

    struct ExchangeRequestCreated has copy, drop {
        pool_id: ID,
        request_id: ID,
        owner: address,
        amount_locked: u64,
    }

    struct ExchangePoolUnlocked has copy, drop {
        pool_id: ID,
        owner: address,
        amount_unlocked: u64,
    }

    public fun new_exchange_pool(ctx: &mut TxContext): ExchangePool {
        let id = object::new(ctx);
        event::emit(ExchangePoolCreated {
            pool_id: object::uid_to_inner(&id),
            owner: sender(ctx),
        });

        ExchangePool {
            id,
            owner: sender(ctx),
            total_expected_e4c_amount: 0,
            exchanging_requests: vec_map::empty(),
        }
    }

    public fun new_exchange_request(
        pool: &mut ExchangePool,
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
        let expected_e4c_balance = amount_locked * exchange_ratio;
        let locked_at = clock::timestamp_ms(clock);
        let locking_end_at = calculate_locking_time(locked_at, exchange_lockup_period_in_days(&detail));
        let id = object::new(ctx);
        let request_id = object::uid_to_inner(&id);
        event::emit(ExchangeRequestCreated {
            pool_id: object::uid_to_inner(&pool.id),
            request_id,
            owner: sender(ctx),
            amount_locked,
        });

        vec_map::insert(&mut pool.exchanging_requests, request_id, ExchangeRequest {
            id,
            amount_locked,
            locked_at,
            locking_end_at,
            detail,
            e4c_balance: coin::into_balance(take_by_friend(inventory, expected_e4c_balance, ctx)),
        });
        pool.total_expected_e4c_amount = pool.total_expected_e4c_amount + expected_e4c_balance;
    }

    /// Unlock the tokens in the pool.
    /// This function can be called only when the locking period is ended and
    /// also by anybody who wants to trigger the unlocking.
    public fun unlock(pool: &mut ExchangePool, request_id: ID, clock: &Clock, ctx: &mut TxContext) {
        let owner = pool.owner;
        let request = get_exchange_request_mut(pool, request_id);
        assert!(request.locking_end_at <= clock::timestamp_ms(clock),
            EExchangePoolLockupPeriodNotPassed
        );
        let balance = balance::value(&request.e4c_balance);
        event::emit(ExchangePoolUnlocked {
            pool_id: object::uid_to_inner(&request.id),
            owner,
            amount_unlocked: balance,
        });
        let coin = coin::take(&mut request.e4c_balance, balance, ctx);
        transfer::public_transfer(coin, owner);
    }

    /// TODO: add withdraw bonus function

    /// TODO: add delete function

    /// === Private Functions ===

    fun get_exchange_request_mut(pool: &mut ExchangePool, request_id: ID): &mut ExchangeRequest {
        /// TODO: Validation
        let index = vec_map::get_idx(&pool.exchanging_requests, &request_id);
        let (_, request) = vec_map::get_entry_by_idx_mut(&mut pool.exchanging_requests, index);
        request
    }
}

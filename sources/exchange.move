module e4c::exchange {

    use std::ascii;
    use std::vector;

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
    use e4c::staking::{offered_bonus_amount, StakingBonusOffer};

    // === Errors ===
    const ELockedAmountMustBeGreaterThanZero: u64 = 1;
    const EInvalidExchangePoolOwner: u64 = 2;
    const EExchangePoolLockupPeriodNotPassed: u64 = 3;
    const EExchangeRequestNotFound: u64 = 4;
    const EExchangeRequestBalanceIsNotZero: u64 = 5;

    // [Shared Object]: ExchangePool is a shared object that represents the pool of locked tokens.
    // The pool is created by the owner and the owner can lock the tokens in the pool.
    struct ExchangePool has key {
        id: UID,
        owner: address,
        total_expected_e4c_amount: u64,
        exchanging_requests: VecMap<ID, ExchangeRequest>
    }

    // [Owned object by ExchangePool]: ExchangeRequest is an owned object by ExchangePool.
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

    struct BonusWithdrawn has copy, drop {
        pool_id: ID,
        owner: address,
        withdrawn_bonus: u64,
        withdrawn_request_id: vector<ID>,
        withdrawn_request_amount: vector<u64>,
    }

    struct ExchangeRequestCreated has copy, drop {
        pool_id: ID,
        request_id: ID,
        owner: address,
        amount_locked: u64,
    }

    struct ExchangePoolUnlocked has copy, drop {
        pool_id: ID,
        request_id: ID,
        owner: address,
        amount_unlocked: u64,
    }

    struct ExchangeRequestDestroyed has copy, drop {
        pool_id: ID,
        request_id: ID,
        owner: address,
    }

    // === Public Functions ===

    // Create a new exchange pool for the user who calls this function.
    // The pool should be turned into a shared object in a PTB.
    // The reason why I don't turn the pool into a shared object in this function is that
    // the client can create a pool and then reqest to exchange in the pool in the same transaction.
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

    // Create a new exchange request in the pool and increase the total expected E4C amount of the pool.
    // This function can be called only by the owner of the pool.
    public fun new_exchange_request(
        pool: &mut ExchangePool,
        action: ascii::String,
        amount_locked: u64,
        clock: &Clock,
        config: &ExchangeConfig,
        inventory: &mut Inventory,
        ctx: &mut TxContext
    ) {
        assert!(pool.owner == sender(ctx), EInvalidExchangePoolOwner);
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

    // Unlock the tokens in the pool.
    // This function can be called only when the locking period is ended and
    // also by anybody who wants to trigger the unlocking.
    public fun unlock(pool: &mut ExchangePool, request_id: ID, clock: &Clock, ctx: &mut TxContext) {
        let owner = pool.owner;
        let pool_id = object::uid_to_inner(&pool.id);
        let request = get_exchange_request_mut(pool, request_id);
        assert!(request.locking_end_at <= clock::timestamp_ms(clock),
            EExchangePoolLockupPeriodNotPassed
        );
        let balance = balance::value(&request.e4c_balance);
        event::emit(ExchangePoolUnlocked {
            pool_id,
            request_id,
            owner,
            amount_unlocked: balance,
        });
        let coin = coin::take(&mut request.e4c_balance, balance, ctx);
        pool.total_expected_e4c_amount = pool.total_expected_e4c_amount - balance;
        transfer::public_transfer(coin, owner);
    }

    // Withdraw the requesting staking bonus from the pool.
    // This function can be called only the moment when the user stakes the E4C.
    // So only the owner of the pool can call this function.
    // The bonus is withdrawn from the pool and transferred to the owner of the pool.
    public fun withdraw_bonus(
        offer: StakingBonusOffer,
        pool: &mut ExchangePool,
        ctx: &mut TxContext
    ) {
        let bonus = balance::zero<E4C>();
        let remaining_amount = offered_bonus_amount(offer);
        let withdrawn_request_id = vector::empty<ID>();
        let withdrawn_request_amount = vector::empty<u64>();
        let (i, len) = (0, vec_map::size(&pool.exchanging_requests));
        let keys = vec_map::keys(&pool.exchanging_requests);
        while (i < len) {
            let request = get_exchange_request_mut(pool, vector::pop_back(&mut keys));
            let available_amount = balance::value(&request.e4c_balance);
            if (available_amount <= remaining_amount) {
                remaining_amount = remaining_amount - available_amount;
                vector::push_back(&mut withdrawn_request_amount, balance::value(&request.e4c_balance));
                balance::join(&mut bonus, balance::withdraw_all(&mut request.e4c_balance));

                // TODO: destroy the empty exchange request
                // destroy_exchange_request(pool, object::uid_as_inner(&request.id), ctx)
            } else {
                let e4c_coin = balance::split(&mut request.e4c_balance, remaining_amount);
                remaining_amount = 0;
                vector::push_back(&mut withdrawn_request_amount, balance::value(&e4c_coin));
                balance::join(&mut bonus, e4c_coin);
            };
            vector::push_back(&mut withdrawn_request_id, object::uid_to_inner(&request.id));
            if (remaining_amount == 0) {
                break
            };
            i = i + 1;
        };
        event::emit(BonusWithdrawn {
            pool_id: object::uid_to_inner(&pool.id),
            owner: pool.owner,
            withdrawn_bonus: balance::value<E4C>(&bonus),
            withdrawn_request_id,
            withdrawn_request_amount,
        });

        transfer::public_transfer(coin::from_balance<E4C>(bonus, ctx), pool.owner);
    }

    // Destroy the exchange request and the get backe the storage rebate.
    // This function can be called only by the owner of the pool.
    public fun destroy_exchange_request(pool: &mut ExchangePool, request_id: ID, ctx: &mut TxContext) {
        assert!(pool.owner == sender(ctx), EInvalidExchangePoolOwner);
        let request = get_exchange_request_mut(pool, request_id);
        assert!(balance::value(&request.e4c_balance) == 0, EExchangeRequestBalanceIsNotZero);

        let (_, request) = vec_map::remove(&mut pool.exchanging_requests, &request_id);
        let ExchangeRequest {
            id,
            amount_locked: _,
            locked_at: _,
            detail: _,
            locking_end_at: _,
            e4c_balance
        } = request;
        event::emit(ExchangeRequestDestroyed {
            pool_id: object::uid_to_inner(&pool.id),
            request_id: object::uid_to_inner(&id),
            owner: sender(ctx),
        });

        balance::destroy_zero(e4c_balance);
        object::delete(id);
    }

    // === Private Functions ===

    fun get_exchange_request_mut(pool: &mut ExchangePool, request_id: ID): &mut ExchangeRequest {
        assert!(vec_map::contains(&pool.exchanging_requests, &request_id), EExchangeRequestNotFound);
        let index = vec_map::get_idx(&pool.exchanging_requests, &request_id);
        let (_, request) = vec_map::get_entry_by_idx_mut(&mut pool.exchanging_requests, index);
        request
    }
}

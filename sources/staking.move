module e4c::staking {
    use sui::balance;
    use sui::balance::Balance;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{sender, TxContext};

    use e4c::config::{
        annualized_interest_rate_bp,
        calculate_locking_time,
        get_staking_rule,
        staking_quantity_range,
        staking_reward, StakingConfig
    };
    use e4c::e4c::{E4C, e4c_tokens_request, GameLiquidityPool};

    // === Errors ===
    const EStakingQuantityTooLow: u64 = 0;
    const EStakingQuantityTooHigh: u64 = 1;
    const EStakingTimeNotEnded: u64 = 2;

    // [Owned Object]: StakingPool represents a pool of staked tokens.
    // The pool will have complete setup upon creation including rewards since it's fixed.
    // Once it's created, you can only unstake the tokens when the staking time is ended.
    struct StakingPool has key {
        id: UID,
        // Amount of tokens staked in the pool
        amount_staked: Balance<E4C>,
        // Time when the pool was created
        staked_at: u64,
        // Staking time in days for the pool
        applied_staking_days: u64,
        // Interest rate applied to the staked tokens
        applied_interest_rate_bp: u16,
        // Time when the staking ends
        staking_end_at: u64,
        // Amount of rewards available for the stakers.
        // The rewards are calculated based on the staking time and the staked amount.
        // The amount is fixed when the pool is created so put the rewards in the pool at the creation time
        // so that user can avoid that the GameLiquidityPool are empty when the rewards are claimed
        reward: Balance<E4C>,
    }

    // Event emitted when a new staking pool is created
    struct Staked has copy, drop {
        pool_id: ID,
        owner: address,
        amount: u64,
    }

    // Event emitted when unstaking tokens from a pool
    struct Unstaked has copy, drop {
        pool_id: ID,
        owner: address,
        amount: u64,
    }
    
    public fun new_staking_pool(
        stake: Coin<E4C>,
        staking_days: u64,
        clock: &Clock,
        config: &StakingConfig,
        liquidity_pool: &mut GameLiquidityPool,
        ctx: &mut TxContext
    ): StakingPool {
        let detail = get_staking_rule(config, staking_days);
        let (min, max) = staking_quantity_range(detail);
        let amount = coin::value(&stake);
        assert!(amount >= min, EStakingQuantityTooLow);
        assert!(amount <= max, EStakingQuantityTooHigh);

        let staked_at = clock::timestamp_ms(clock);
        let reward = staking_reward(config, staking_days, amount);
        let id = object::new(ctx);
        let pool_id = object::uid_to_inner(&id);

        event::emit(Staked {
            pool_id,
            owner: sender(ctx),
            amount
        });

        StakingPool {
            id,
            amount_staked: coin::into_balance(stake),
            staked_at,
            applied_staking_days: staking_days,
            applied_interest_rate_bp: annualized_interest_rate_bp(detail),
            staking_end_at: calculate_locking_time(staked_at, staking_days),
            reward: coin::into_balance(e4c_tokens_request(liquidity_pool, reward, ctx))
        }
    }

    // Unstake the tokens from the pool.
    // This function can be called only when the staking time is ended
    public fun unstake(
        pool: StakingPool,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<E4C> {
        assert!(
            pool.staking_end_at <= clock::timestamp_ms(clock),
            EStakingTimeNotEnded
        );

        let StakingPool {
            id,
            amount_staked,
            staked_at: _,
            applied_staking_days: _,
            applied_interest_rate_bp: _,
            staking_end_at: _,
            reward
        } = pool;

        event::emit(Unstaked {
            pool_id: object::uid_to_inner(&id),
            owner: sender(ctx),
            amount: balance::value(&amount_staked) + balance::value(&reward)
        });
        let coin = coin::from_balance(amount_staked, ctx);
        coin::join(&mut coin, coin::from_balance(reward, ctx));
        object::delete(id);
        coin
    }
}

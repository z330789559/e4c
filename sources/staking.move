module e4c::staking {
    use sui::balance;
    use sui::balance::Balance;
    use sui::clock;
    use sui::clock::Clock;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::event;
    use sui::object;
    use sui::object::{ID, UID};
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};
    
    use e4c::config::{
        annualized_interest_rate_bp,
        get_staking_details,
        reward,
        staking_quantity_range,
        staking_time_end,
        StakingConfig
    };
    use e4c::e4c::E4C;
    
    /// === Errors ===
    const EStakingQuantityTooLow: u64 = 0;
    const EStakingQuantityTooHigh: u64 = 1;
    const EStakingTimeNotEnded: u64 = 2;
    const EStakingPoolNotEmptied: u64 = 3;
    const EInvalidStakingPoolOwner: u64 = 4;
    
    /// [Shared Object]: StakingPool represents a pool of staked tokens.
    /// The pool will be created by a user and will have a reward rate that will be used to calculate the rewards for the stakers.
    struct StakingPool has key {
        id: UID,
        /// Address of the pool owner
        owner: address,
        /// Amount of tokens staked in the pool
        amount_staked: Balance<E4C>,
        /// Time when the pool was created
        staked_at: u64,
        /// Staking time in days for the pool
        applied_staking_time: u64,
        /// Interest rate applied to the staked tokens
        applied_interest_rate_bp: u16,
        /// Expected amount of rewards
        expected_reward: u64,
    }
    
    /// Event emitted when a new staking pool is created
    struct Staked has copy, drop {
        pool_id: ID,
        owner: address,
        amount: u64,
    }
    
    /// Event emitted when unstaking tokens from a pool
    struct Unstaked has copy, drop {
        pool_id: ID,
        owner: address,
        amount: u64,
    }
    
    /// Event emitted when a staking pool is destroyed
    struct PoolDestroyed has copy, drop {
        pool_id: ID,
    }
    
    public fun new_staking_pool(
        config: &StakingConfig,
        stake: Coin<E4C>,
        staking_time: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let detail = get_staking_details(config, staking_time);
        let (min, max) = staking_quantity_range(detail);
        let amount = coin::value(&stake);
        assert!(amount >= min, EStakingQuantityTooLow);
        assert!(amount <= max, EStakingQuantityTooHigh);
        
        let expected_reward = reward(config, staking_time, amount);
        let id = object::new(ctx);
        
        event::emit(Staked {
            pool_id: object::uid_to_inner(&id),
            owner: sender(ctx),
            amount
        });
        let pool = StakingPool {
            id,
            owner: sender(ctx),
            amount_staked: coin::into_balance(stake),
            staked_at: clock::timestamp_ms(clock),
            applied_staking_time: staking_time,
            applied_interest_rate_bp: annualized_interest_rate_bp(detail),
            expected_reward
        };
        transfer::share_object(pool);
    }
    
    public fun unstake(
        treasury_cap: &mut TreasuryCap<E4C>,
        pool: &mut StakingPool,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<E4C> {
        assert!(
            staking_time_end(pool.applied_staking_time, pool.staked_at) <= clock::timestamp_ms(clock),
            EStakingTimeNotEnded
        );
        let amount = balance::value(&pool.amount_staked);
        assert!(amount > 0, EStakingPoolNotEmptied);
        let coin = coin::take(&mut pool.amount_staked, amount, ctx);
        let reward = coin::mint(treasury_cap, pool.expected_reward - amount, ctx);
        
        event::emit(Unstaked {
            pool_id: object::uid_to_inner(&pool.id),
            owner: sender(ctx),
            amount
        });
        coin::join(&mut coin, reward);
        coin
    }
    
    public fun destroy_staking_pool(
        pool: StakingPool,
        ctx: &mut TxContext
    ) {
        assert!(pool.owner == sender(ctx), EInvalidStakingPoolOwner);
        assert!(balance::value(&pool.amount_staked) == 0, EStakingPoolNotEmptied);
        let StakingPool {
            id,
            owner: _,
            amount_staked: balance,
            staked_at: _,
            applied_staking_time: _,
            applied_interest_rate_bp: _,
            expected_reward: _
        } = pool;
        balance::destroy_zero(balance);
        event::emit(PoolDestroyed {
            pool_id: object::uid_to_inner(&id)
        });
        object::delete(id);
    }
}

module e4c::staking {
    use sui::balance;
    use sui::balance::Balance;
    use sui::clock;
    use sui::clock::Clock;
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object;
    use sui::object::{ID, UID};
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};

    use e4c::config::{
        annualized_interest_rate_bp,
        get_staking_detail,
        staking_quantity_range,
        staking_reward,
        staking_time_end, StakingConfig
    };
    use e4c::e4c::{E4C, Inventory, take_by_friend};

    /// === Errors ===
    const EStakingQuantityTooLow: u64 = 0;
    const EStakingQuantityTooHigh: u64 = 1;
    const EStakingTimeNotEnded: u64 = 2;
    const EStakingPoolEmptied: u64 = 3;
    const EStakingPoolShouldBeEmptied: u64 = 4;
    const EInvalidStakingPoolOwner: u64 = 5;

    /// [Shared Object]: StakingPool represents a pool of staked tokens.
    /// The pool will be created by a user and will have a reward rate that will be used to calculate the rewards for the stakers.
    /// Once it's created, you can only unstake the tokens when the staking time is ended.
    struct StakingPool has key {
        id: UID,
        /// TODO: Consider to use key object when claiming instead of seeing the match of the owner
        /// Address of the pool owner
        owner: address,
        /// Amount of tokens staked in the pool
        amount_staked: Balance<E4C>,
        /// Time when the pool was created
        staked_at: u64,
        /// Staking time in days for the pool
        applied_staking_days: u64,
        /// Interest rate applied to the staked tokens
        applied_interest_rate_bp: u16,
        /// Amount of rewards available for the stakers.
        /// The rewards are calculated based on the staking time and the staked amount.
        /// The amount is fixed when the pool is created so put the rewards in the pool at the creation time
        /// so that user can avoid that the inventory are empty when the rewards are claimed
        reward: Balance<E4C>,
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

    /// TODO: The number of E4C tokens locked for exchange should be unlocked immediately.
    ///     The number to be unlocked is equal to the number of tokens try to be staked.
    public fun new_staking_pool(
        stake: Coin<E4C>,
        staking_time: u64,
        clock: &Clock,
        config: &StakingConfig,
        inventory: &mut Inventory,
        ctx: &mut TxContext
    ) {
        let detail = get_staking_detail(config, staking_time);
        let (min, max) = staking_quantity_range(detail);
        let amount = coin::value(&stake);
        assert!(amount >= min, EStakingQuantityTooLow);
        assert!(amount <= max, EStakingQuantityTooHigh);

        let reward = staking_reward(config, staking_time, amount);
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
            applied_staking_days: staking_time,
            applied_interest_rate_bp: annualized_interest_rate_bp(detail),
            reward: coin::into_balance(take_by_friend(inventory, reward, ctx))
        };
        transfer::share_object(pool);
    }

    public fun new_staking_pool_by_bonus(
        stake: Coin<E4C>,
        staking_time: u64,
        clock: &Clock,
        config: &StakingConfig,
        inventory: &mut Inventory,
        ctx: &mut TxContext
    ) {
        new_staking_pool(stake, staking_time, clock, config, inventory, ctx);
    }

    public fun unstake(
        pool: &mut StakingPool,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<E4C> {
        assert!(pool.owner == sender(ctx), EInvalidStakingPoolOwner);
        assert!(
            staking_time_end(pool.applied_staking_days, pool.staked_at) <= clock::timestamp_ms(clock),
            EStakingTimeNotEnded
        );
        let (staked, reward) = (balance::value(&pool.amount_staked), balance::value(&pool.reward));
        assert!(staked > 0 && reward > 0, EStakingPoolEmptied);
        let (staked_coin, reward_coin) = (coin::take(&mut pool.amount_staked, staked, ctx), coin::take(
            &mut pool.reward,
            staked,
            ctx
        ));

        event::emit(Unstaked {
            pool_id: object::uid_to_inner(&pool.id),
            owner: sender(ctx),
            amount: staked
        });
        coin::join(&mut staked_coin, reward_coin);
        staked_coin
    }

    /// TODO: Consider to inject the logic into the unstake function
    ///  need to check if it's possible to delete &mut UID in ustake function
    ///  should I keep the logic as it is?
    public fun destroy_staking_pool(
        pool: StakingPool,
        ctx: &mut TxContext
    ) {
        assert!(pool.owner == sender(ctx), EInvalidStakingPoolOwner);
        assert!(balance::value(&pool.amount_staked) == 0, EStakingPoolShouldBeEmptied);
        let StakingPool {
            id,
            owner: _,
            amount_staked: balance_staked,
            staked_at: _,
            applied_staking_days: _,
            applied_interest_rate_bp: _,
            reward: balance_reward,
        } = pool;
        balance::destroy_zero(balance_staked);
        balance::destroy_zero(balance_reward);
        event::emit(PoolDestroyed {
            pool_id: object::uid_to_inner(&id)
        });
        object::delete(id);
    }
}

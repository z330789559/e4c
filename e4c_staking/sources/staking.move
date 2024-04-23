module e4c_staking::staking {
    use sui::balance;
    use sui::balance::Balance;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::event;
    // use sui::object;
    // use sui::transfer;
    use sui::tx_context::{sender};

    use e4c::e4c::E4C;
    use e4c_staking::config::{
        annualized_interest_rate_bp,
        calculate_locking_time,
        get_staking_rule,
        staking_quantity_range,
        staking_reward,
        StakingConfig};

    // === Errors ===
    const EStakingQuantityTooLow: u64 = 0;
    const EStakingQuantityTooHigh: u64 = 1;
    const EStakingTimeNotEnded: u64 = 2;
    const EAmountMustBeGreaterThanZero: u64 = 3;
    const EAmountTooHigh: u64 = 4;

    // [Owned Object]: StakingReceipt represents a receipt of staked tokens.
    // The receipt will have complete setup upon creation including rewards since it's fixed.
    // Once it's created, you can only unstake the tokens when the staking time is ended.
    public struct StakingReceipt has key {
        id: UID,
        // Amount of tokens staked in the receipt
        amount_staked: Balance<E4C>,
        // Time when the receipt was created
        staked_at: u64,
        // Staking time in days for the receipt
        applied_staking_days: u64,
        // Interest rate applied to the staked tokens
        applied_interest_rate_bp: u16,
        // Time when the staking ends
        staking_end_at: u64,
        // Amount of rewards available for the stakers.
        // The rewards are calculated based on the staking time and the staked amount.
        // The amount is fixed when the receipt is created so put the rewards in the receipt at the creation time
        // so that user can avoid that the GameLiquidityPool are empty when the rewards are claimed
        reward: Balance<E4C>,
    }

    // [Shared Object]: GameLiquidityPool is a store of minted E4C tokens.
    public struct GameLiquidityPool has key, store {
        id: UID,
        balance: Balance<E4C>,
    }

    // Event emitted when a new staking receipt is created
    public struct Staked has copy, drop {
        receipt_id: ID,
        owner: address,
        amount: u64,
    }

    // Event emitted when unstaking tokens from a receipt
    public struct Unstaked has copy, drop {
        receipt_id: ID,
        owner: address,
        amount: u64,
    }

    // Event emitted when E4C tokens are placed in the GameLiquidityPool
    public struct PoolPlaced has copy, drop {
        sender: address,
        amount: u64,
    }

    // Event emitted when E4C tokens are taken from the GameLiquidityPool
    public struct PoolWithdrawn has copy, drop {
        sender: address,
        amount: u64,
    }

    fun init(ctx: &mut TxContext) {
        transfer::public_share_object(
            GameLiquidityPool { id: object::new(ctx), balance: balance::zero() }
        );
    }

    // == Public Functions ==

    // Create a new staking receipt with the given stake and staking days.
    public fun new_staking_receipt(
        stake: Coin<E4C>,
        staking_days: u64,
        clock: &Clock,
        config: &StakingConfig,
        liquidity_pool: &mut GameLiquidityPool,
        ctx: &mut TxContext
    ): StakingReceipt {
        let detail = get_staking_rule(config, staking_days);
        let (min, max) = staking_quantity_range(detail);
        let amount = coin::value(&stake);
        assert!(amount >= min, EStakingQuantityTooLow);
        assert!(amount <= max, EStakingQuantityTooHigh);

        let staked_at = clock::timestamp_ms(clock);
        let reward = staking_reward(config, staking_days, amount);
        let id = object::new(ctx);
        let receipt_id = object::uid_to_inner(&id);

        event::emit(Staked {
            receipt_id,
            owner: sender(ctx),
            amount
        });

        StakingReceipt {
            id,
            amount_staked: coin::into_balance(stake),
            staked_at,
            applied_staking_days: staking_days,
            applied_interest_rate_bp: annualized_interest_rate_bp(detail),
            staking_end_at: calculate_locking_time(staked_at, staking_days),
            reward: coin::into_balance(e4c_tokens_request(liquidity_pool, reward, ctx))
        }
    }

    // Unstake the tokens from the receipt.
    // This function can be called only when the staking time is ended
    public fun unstake(
        receipt: StakingReceipt,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<E4C> {
        assert!(
            receipt.staking_end_at <= clock::timestamp_ms(clock),
            EStakingTimeNotEnded
        );

        let StakingReceipt {
            id,
            amount_staked,
            staked_at: _,
            applied_staking_days: _,
            applied_interest_rate_bp: _,
            staking_end_at: _,
            reward
        } = receipt;

        event::emit(Unstaked {
            receipt_id: object::uid_to_inner(&id),
            owner: sender(ctx),
            amount: balance::value(&amount_staked) + balance::value(&reward)
        });
        object::delete(id);

        let mut total_reward_coin = coin::from_balance(amount_staked, ctx);
        let reward_amount = coin::from_balance(reward, ctx);
        coin::join(&mut total_reward_coin, reward_amount);
        total_reward_coin
    }

    // Put back E4C tokens to the GameLiquidityPool without capability check.
    // This function can be called by anyone.
    public fun place_in_pool(liquidity_pool: &mut GameLiquidityPool, coin: Coin<E4C>, ctx: &mut TxContext) {
        assert!(coin::value(&coin) > 0, EAmountMustBeGreaterThanZero);

        event::emit(PoolPlaced {
            sender: sender(ctx),
            amount: coin::value(&coin)
        });
        balance::join(&mut liquidity_pool.balance, coin::into_balance(coin));
    }

    // === Private Functions ===

    // Take E4C tokens from the GameLiquidityPool without capability check.
    // This function is only accessible to the friend module.
    fun e4c_tokens_request(
        liquidity_pool: &mut GameLiquidityPool,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<E4C> {
        assert!(amount > 0, EAmountMustBeGreaterThanZero);
        assert!(amount <= balance::value(&liquidity_pool.balance), EAmountTooHigh);

        event::emit(PoolWithdrawn {
            sender: sender(ctx),
            amount
        });
        let coin = coin::take(&mut liquidity_pool.balance, amount, ctx);
        coin
    }
    // === Public view Functions ===
    public fun game_liquidity_pool_balance(liquidity_pool: &GameLiquidityPool): u64 {
        balance::value(&liquidity_pool.balance)
    }

    public fun staking_receipt_data(receipt: &StakingReceipt): (u64, u64, u64, u16, u64) {
        (
            balance::value(&receipt.amount_staked),
            receipt.staked_at,
            receipt.applied_staking_days,
            receipt.applied_interest_rate_bp,
            receipt.staking_end_at
        )
    }

    // === Testing Functions ===

    #[test_only] use e4c_staking::config::init_for_testing as config_init;
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
       init(ctx);
       config_init(ctx);
    }
}

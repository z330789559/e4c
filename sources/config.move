module e4c::config {
    use std::ascii;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};

    use e4c::e4c::InventoryCap;

    /// === Errors ===
    const EIncorrectBasisPoints: u64 = 0;
    const EStakingTimeMissing: u64 = 1;
    const EStakingTimeConflict: u64 = 2;
    const EStakingQuantityRangeUnmatch: u64 = 3;

    /// === Constants ===
    const MAX_U64: u64 = 18446744073709551615;
    const MAX_BPS: u16 = 10_000;


    /// === Structs ===

    /// [Shared Object]: StakingConfig is a configuration for staking
    struct StakingConfig has key, store {
        id: UID,
        /// staking time in days -> staking details
        staking_details: VecMap<u64, StakingDetail>,
    }

    struct StakingDetail has store {
        /// staking time in days
        staking_time: u64,
        /// annualized interest rate in basis points
        annualized_interest_rate_bp: u16,
        /// decided the range of staking quantity
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64,
    }

    /// [Shared Object]: ExchangeConfig is a configuration for exchange
    struct ExchangeConfig has key, store {
        id: UID,
        /// exchange action name -> exchange details
        exchange_details: VecMap<ascii::String, ExchangeDetail>,
    }

    /// TODO: is it safe to use `copy` here?
    struct ExchangeDetail has store, copy {
        /// exchange action name
        action: ascii::String,
        /// lockup period in days
        lockup_period_in_days: u64,
        /// exchange ratio from X to E4C: 1: <value> = $E4C : X
        exchange_ratio: u64,
    }

    fun init(ctx: &mut TxContext) {
        /// staking config initialization
        let config = StakingConfig {
            id: object::new(ctx),
            staking_details: vec_map::empty<u64, StakingDetail>(),
        };
        vec_map::insert(&mut config.staking_details, 30, StakingDetail {
            staking_time: 30, // 30 days
            annualized_interest_rate_bp: 1000, /// 10%
            staking_quantity_range_min: 1,
            staking_quantity_range_max: 100,
        });
        vec_map::insert(&mut config.staking_details, 60, StakingDetail {
            staking_time: 60, // 60 days
            annualized_interest_rate_bp: 2000, /// 20%
            staking_quantity_range_min: 100,
            staking_quantity_range_max: 1000,
        });
        vec_map::insert(&mut config.staking_details, 90, StakingDetail {
            staking_time: 90, // 90 days
            annualized_interest_rate_bp: 3000, /// 30%
            staking_quantity_range_min: 1000,
            staking_quantity_range_max: MAX_U64,
        });

        /// exchange config initialization
        let exchange_config = ExchangeConfig {
            id: object::new(ctx),
            exchange_details: vec_map::empty<ascii::String, ExchangeDetail>(),
        };
        vec_map::insert(&mut exchange_config.exchange_details, ascii::string(b"arena_gem_exchanging"), ExchangeDetail {
            action: ascii::string(b"arena_gem_exchanging"),
            lockup_period_in_days: 10, // 10 days
            exchange_ratio: 10, // 1:10 = $E4C : Arena Gem
        });

        transfer::public_share_object(config);
        transfer::public_share_object(exchange_config);
    }

    /// === Staking Config Functions ===

    /// https://mysten-labs.slack.com/archives/C04J99F4B2L/p1701194354270349?thread_ts=1701171910.032099&cid=C04J99F4B2L
    public fun get_staking_detail(config: &StakingConfig, staking_time: u64): &StakingDetail {
        /// TODO: Validation
        let index = vec_map::get_idx(&config.staking_details, &staking_time);
        let (_, details) = vec_map::get_entry_by_idx(&config.staking_details, index);
        details
    }

    public(friend) fun add_staking_detail(
        _: &InventoryCap,
        config: &mut StakingConfig,
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64
    ) {
        assert!(staking_time > 0, EStakingTimeMissing);
        assert!(annualized_interest_rate_bp <= MAX_BPS, EIncorrectBasisPoints);
        assert!(vec_map::contains(&config.staking_details, &staking_time) == false, EStakingTimeConflict);
        assert!(staking_quantity_range_min < staking_quantity_range_max, EStakingQuantityRangeUnmatch);
        /// TODO: add other validation like nothing conflict with existing staking details

        vec_map::insert(&mut config.staking_details, staking_time, StakingDetail {
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
        });
        /// TODO: add event
    }

    public(friend) fun remove_staking_detail(
        _: &InventoryCap,
        config: &mut StakingConfig,
        staking_time: u64
    ): StakingDetail {
        let (_, config) = vec_map::remove(&mut config.staking_details, &staking_time);
        config
        /// TODO: add event
    }

    /// === Public-View Functions ===

    /// TODO: Cosider to move to "staking" module
    public fun staking_reward(
        config: &StakingConfig,
        staking_time: u64,
        staking_quantity: u64
    ): u64 {
        let detail = get_staking_detail(config, staking_time);
        /// Formula: reward = (N * T / 360 * amountE4C) + amountE4C
        /// N = annualized interest rate in basis points
        /// T = staking time in days
        let reward = (((detail.annualized_interest_rate_bp as u64) * staking_time / 360) * staking_quantity + staking_quantity) / 1000;
        reward
    }

    public fun staking_quantity_range(
        detail: &StakingDetail,
    ): (u64, u64) {
        (detail.staking_quantity_range_min, detail.staking_quantity_range_max)
    }

    public fun annualized_interest_rate_bp(
        detail: &StakingDetail,
    ): u16 {
        detail.annualized_interest_rate_bp
    }

    /// === Exchange Config Functions ===

    /// https://mysten-labs.slack.com/archives/C04J99F4B2L/p1701194354270349?thread_ts=1701171910.032099&cid=C04J99F4B2L
    public fun get_exchange_detail(config: &ExchangeConfig, action: ascii::String): ExchangeDetail {
        /// TODO: Validation
        let index = vec_map::get_idx(&config.exchange_details, &action);
        let (_, detail) = vec_map::get_entry_by_idx(&config.exchange_details, index);
        *detail
    }

    public fun exchange_lockup_period_in_days(detail: &ExchangeDetail): u64 {
        detail.lockup_period_in_days
    }

    public fun exchange_ratio(detail: &ExchangeDetail): u64 {
        detail.exchange_ratio
    }

    /// === Helper Functions ===

    /// Calculate the locking time in milliseconds
    ///     base_timestamp: the base timestamp in milliseconds
    ///     locking_days: the number of days to lock
    public fun calculate_locking_time(
        base_timestamp: u64,
        locking_days: u64
    ): u64 {
        base_timestamp + locking_days * 24 * 60 * 60 * 1000
    }

    #[test_only]
    public fun new_staking_details(
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64
    ): StakingDetail {
        StakingDetail {
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
        }
    }

    #[test_only]
    public fun new_staking_config(
        details: StakingDetail, staking_time: u64, ctx: &mut TxContext
    ): StakingConfig {
        let config = StakingConfig {
            id: object::new(ctx),
            staking_details: vec_map::empty(),
        };
        vec_map::insert(&mut config.staking_details, staking_time, details);
        config
    }
}

module e4c::config {
    use sui::object;
    use sui::object::UID;
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map;
    use sui::vec_map::VecMap;
    
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
    
    struct StakingDetails has store {
        /// staking time in days
        staking_time: u64,
        /// annualized interest rate in basis points
        annualized_interest_rate_bp: u16,
        /// decided the range of staking quantity
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64,
    }
    
    /// [Shared Object]: StakingConfig is a configuration for staking
    struct StakingConfig has key, store {
        id: UID,
        /// staking time in days -> staking details
        staking_details: VecMap<u64, StakingDetails>,
    }
    
    fun init(ctx: &mut TxContext) {
        let config = StakingConfig {
            id: object::new(ctx),
            staking_details: vec_map::empty<u64, StakingDetails>(),
        };
        vec_map::insert(&mut config.staking_details, 30, StakingDetails {
            staking_time: 30,
            annualized_interest_rate_bp: 1000, /// 10%
            staking_quantity_range_min: 1,
            staking_quantity_range_max: 100,
        });
        vec_map::insert(&mut config.staking_details, 60, StakingDetails {
            staking_time: 60,
            annualized_interest_rate_bp: 2000, /// 20%
            staking_quantity_range_min: 100,
            staking_quantity_range_max: 1000,
        });
        vec_map::insert(&mut config.staking_details, 90, StakingDetails {
            staking_time: 90,
            annualized_interest_rate_bp: 3000, /// 30%
            staking_quantity_range_min: 1000,
            staking_quantity_range_max: MAX_U64,
        });
        transfer::public_share_object(config);
    }
    
    /// https://mysten-labs.slack.com/archives/C04J99F4B2L/p1701194354270349?thread_ts=1701171910.032099&cid=C04J99F4B2L
    public fun get_staking_details(config: &StakingConfig, staking_time: u64): &StakingDetails {
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
        
        vec_map::insert(&mut config.staking_details, staking_time, StakingDetails {
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
    ): StakingDetails {
        let (_, config) = vec_map::remove(&mut config.staking_details, &staking_time);
        config
        /// TODO: add event
    }
    
    /// === Public-View Functions ===
    
    /// TODO: Cosider to move to "staking" module
    public fun reward(
        config: &StakingConfig,
        staking_time: u64,
        staking_quantity: u64
    ): u64 {
        let detail = get_staking_details(config, staking_time);
        /// Formula: reward = (N * T / 360 * amountE4C) + amountE4C
        /// N = annualized interest rate in basis points
        /// T = staking time in days
        let reward = (((detail.annualized_interest_rate_bp as u64) * staking_time / 360) * staking_quantity + staking_quantity) / 1000;
        reward
    }
    
    public fun staking_quantity_range(
        detail: &StakingDetails,
    ): (u64, u64) {
        (detail.staking_quantity_range_min, detail.staking_quantity_range_max)
    }
    
    public fun annualized_interest_rate_bp(
        detail: &StakingDetails,
    ): u16 {
        detail.annualized_interest_rate_bp
    }
    
    public fun staking_time_end(
        staking_time: u64,
        timestamp: u64
    ): u64 {
        timestamp + staking_time * 24 * 60 * 60 * 1000
    }
    
    #[test_only]
    public fun new_staking_details(
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64
    ): StakingDetails {
        StakingDetails {
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
        }
    }
    
    #[test_only]
    public fun new_staking_config(
        details: StakingDetails, staking_time: u64, ctx: &mut TxContext
    ): StakingConfig {
        let config = StakingConfig {
            id: object::new(ctx),
            staking_details: vec_map::empty(),
        };
        vec_map::insert(&mut config.staking_details, staking_time, details);
        config
    }
}

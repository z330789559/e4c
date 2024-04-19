module e4c::config {
    use sui::object::{Self, UID};
    use sui::package;
    use sui::transfer;
    use sui::tx_context::{sender, TxContext};
    use sui::vec_map::{Self, VecMap};

    // === Errors ===
    const EIncorrectBasisPoints: u64 = 0;
    const EStakingTimeMustBeGreaterThanZero: u64 = 1;
    const EStakingTimeConflict: u64 = 2;
    const EStakingQuantityRangeUnmatch: u64 = 3;
    const EStakingTimeNotFound: u64 = 4;

    // === Constants ===
    const MAX_U64: u64 = 18446744073709551615;
    const MAX_BPS: u16 = 10_000;


    // === Structs ===

    // [One Time Witness] CONFIG is a one-time witness that is used to initialize the e4c package
    struct CONFIG has drop {}

    // [Owned Object]: AdminCap is a capability that allows a holder to access the entire $E4C token configuration
    struct AdminCap has key, store { id: UID }

    // [Shared Object]: StakingConfig is a configuration for staking
    struct StakingConfig has key, store {
        id: UID,
        // staking time in days -> staking rules
        staking_rules: VecMap<u64, StakingRule>,
    }

    struct StakingRule has store, drop {
        // staking time in days
        staking_time: u64,
        // annualized interest rate in basis points
        annualized_interest_rate_bp: u16,
        // decided the range of staking quantity
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64,
    }

    fun init(otw: CONFIG, ctx: &mut TxContext) {
        // staking config initialization
        let config = StakingConfig {
            id: object::new(ctx),
            staking_rules: vec_map::empty<u64, StakingRule>(),
        };
        vec_map::insert(&mut config.staking_rules, 30, StakingRule {
            staking_time: 30, // 30 days
            annualized_interest_rate_bp: 1000, // 10%
            staking_quantity_range_min: 1,
            staking_quantity_range_max: 100,
        });
        vec_map::insert(&mut config.staking_rules, 60, StakingRule {
            staking_time: 60, // 60 days
            annualized_interest_rate_bp: 2000, // 20%
            staking_quantity_range_min: 100,
            staking_quantity_range_max: 1000,
        });
        vec_map::insert(&mut config.staking_rules, 90, StakingRule {
            staking_time: 90, // 90 days
            annualized_interest_rate_bp: 3000, // 30%
            staking_quantity_range_min: 1000,
            staking_quantity_range_max: MAX_U64,
        });

        transfer::public_share_object(config);
        transfer::public_transfer(AdminCap { id: object::new(ctx) }, sender(ctx));
        package::claim_and_keep(otw, ctx);
    }

    // === Staking Config Functions ===

    // https://mysten-labs.slack.com/archives/C04J99F4B2L/p1701194354270349?thread_ts=1701171910.032099&cid=C04J99F4B2L
    public fun get_staking_rule(config: &StakingConfig, staking_time: u64): &StakingRule {
        assert!(vec_map::contains(&config.staking_rules, &staking_time), EStakingTimeNotFound);
        let index = vec_map::get_idx(&config.staking_rules, &staking_time);
        let (_, rules) = vec_map::get_entry_by_idx(&config.staking_rules, index);
        rules
    }

    public(friend) fun add_staking_rule(
        _: &AdminCap,
        config: &mut StakingConfig,
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64
    ) {
        assert!(staking_time > 0, EStakingTimeMustBeGreaterThanZero);
        assert!(annualized_interest_rate_bp <= MAX_BPS, EIncorrectBasisPoints);
        assert!(vec_map::contains(&config.staking_rules, &staking_time) == false, EStakingTimeConflict);
        assert!(staking_quantity_range_min < staking_quantity_range_max, EStakingQuantityRangeUnmatch);

        vec_map::insert(&mut config.staking_rules, staking_time, StakingRule {
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
        });
        // TODO: add event
    }

    public(friend) fun remove_staking_rule(
        _: &AdminCap,
        config: &mut StakingConfig,
        staking_time: u64
    ): StakingRule {
        let (_, config) = vec_map::remove(&mut config.staking_rules, &staking_time);
        config
        // TODO: add event
    }

    // === Public-View Functions ===

    // TODO: Consider moving to "staking" module
    public fun staking_reward(
        config: &StakingConfig,
        staking_time: u64,
        staking_quantity: u64
    ): u64 {
        let rule = get_staking_rule(config, staking_time);
        // Formula: reward = (N * T / 360 * amountE4C) + amountE4C
        // N = annualized interest rate in basis points
        // T = staking time in days
        let reward = (((rule.annualized_interest_rate_bp as u64) * staking_time / 360) * staking_quantity + staking_quantity) / 1000;
        reward
    }

    public fun staking_quantity_range(
        rule: &StakingRule,
    ): (u64, u64) {
        (rule.staking_quantity_range_min, rule.staking_quantity_range_max)
    }

    public fun annualized_interest_rate_bp(
        rule: &StakingRule,
    ): u16 {
        rule.annualized_interest_rate_bp
    }

    // Calculate the locking time in milliseconds
    //     base_timestamp: the base timestamp in milliseconds
    //     locking_days: the number of days to lock
    public fun calculate_locking_time(
        base_timestamp: u64,
        locking_days: u64
    ): u64 {
        base_timestamp + locking_days * 24 * 60 * 60 * 1000
    }

    #[test_only]
    public fun new_staking_rules(
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64
    ): StakingRule {
        StakingRule {
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
        }
    }

    #[test_only]
    public fun new_staking_config(
        rules: StakingRule, staking_time: u64, ctx: &mut TxContext
    ): StakingConfig {
        let config = StakingConfig {
            id: object::new(ctx),
            staking_rules: vec_map::empty(),
        };
        vec_map::insert(&mut config.staking_rules, staking_time, rules);
        config
    }
}

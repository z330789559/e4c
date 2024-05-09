#[test_only]
module e4c_staking::config_tests {
    use sui::{
        clock,
        test_utils::{assert_eq, destroy},
        test_scenario as ts
    };
    use e4c_staking::config::{AdminCap, StakingConfig, Self,
                EStakingTimeNotFound , EStakingTimeMustBeGreaterThanZero, EIncorrectBasisPoints,
                EStakingTimeConflict, EStakingQuantityRangeUnmatch };
    const NEW_STAKING_TIME: u64 = 300;
    const NEW_ANNUALIZED_INTEREST_RATE_BP: u16 = 3610;
    const NEW_STAKING_QUANTITY_RANGE_MIN: u64 = 3620;
    const NEW_STAKING_QUANTITY_RANGE_MAX: u64 = 36300;
    const STAKING_AMOUNT: u64 = 3620;
    const PRE_CALCULATION_STAKING_REWARD: u64 = 1089;
    
    const TARGETED_REMOVE_STAKING_TIME: u64 = 90;
    const REMOVING_STAKING_QUANTITY_RANGE_MIN: u64 = 1000;
    const REMOVING_ANNUALIZED_INTEREST_RATE_BP: u16 = 1500;

    const RANGE_MAX_U64: u64 = 18446744073709551615;
    const RANGE_MAX_U16: u16 = 65535;

    const MAX_BPS: u16 = 10_000;
    const E4C_DECIMALS: u64 = 1_000_000_000;

    fun reward_fuzzing(
        staking_quantity: u64, 
        staking_time: u64, 
        annualized_interest_rate_bp: u16, 
        staking_quantity_range_min: u64, staking_quantity_range_max: u64, 
        expected_reward: u64) {
        let mut ctx = tx_context::dummy();
        
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let fuzzy_config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = fuzzy_config.staking_reward(staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(fuzzy_config);
    }

    // ADD STAKING RULE CASES NO.1
    // stake_time: 30 days
    // annualized_interest_rate_bp: 800 : 8%
    // staking_quantity_range_min: 1
    // staking_quantity_range_max: 100
    #[test]
    fun test_manual_fuzzy_on_reward_change_1() {
        reward_fuzzing(100 * E4C_DECIMALS, 30, 800, 1 * E4C_DECIMALS, 100 * E4C_DECIMALS, 670000000);
    }

    // ADD STAKING RULE CASES NO.2
    // stake_time: 60 days
    // annualized_interest_rate_bp: 1000 : 10%
    // staking_quantity_range_min: 100
    // staking_quantity_range_max: 1000
    #[test]
    fun test_manual_fuzzy_on_reward_change_2() {
        reward_fuzzing(1_000 * E4C_DECIMALS, 60, 1000, 100 * E4C_DECIMALS, 1000 * E4C_DECIMALS, 16700000000);
    }

    // ADD STAKING RULE CASES NO.3
    // stake_time: 90 days
    // annualized_interest_rate_bp: 1500 : 15%
    // staking_quantity_range_min: 1000
    // staking_quantity_range_max: 18446744073709551615 : MAX_U64
    #[test]
    fun test_manual_fuzzy_on_reward_change_3() {
        reward_fuzzing(10_000 * E4C_DECIMALS, 90, 1500, 10_000 * E4C_DECIMALS, 1_000_000_000 * E4C_DECIMALS, 375000000000);
    }

    // ADD STAKING RULE EDGE CASES NO.1
    // stake_time: 360 day
    // annualized_interest_rate_bp: 1 : 0.01%
    #[test]
    fun test_manual_fuzzy_on_reward_MAX_U64_1() {
        reward_fuzzing(RANGE_MAX_U64, 360, 1, 3000 * E4C_DECIMALS, RANGE_MAX_U64, 1844674407370955);
    }

    // ADD STAKING RULE EDGE CASES NO.2
    // stake_time: 360 day
    // annualized_interest_rate_bp: 1 : 0.01%
    #[test]
    fun test_error_manual_fuzzy_on_reward_MAX_U64_2() {
        reward_fuzzing(1 * E4C_DECIMALS, 360, 1, 1 * E4C_DECIMALS, RANGE_MAX_U64, 100000);
    }
    
    // ADD STAKING RULE EDGE CASES NO.3
    // stake_time: RANGE_MAX_U64 day
    // annualized_interest_rate_bp: 1 : 0.01%

    #[test]
    #[expected_failure]
    fun test_manual_fuzzy_on_reward_edge() {
        reward_fuzzing(1 * E4C_DECIMALS, RANGE_MAX_U64, 1, 1 * E4C_DECIMALS, 100 * E4C_DECIMALS, 512409557603043);
    }

    // failed to overflow u64
    #[test]
    #[expected_failure]
    fun test_manual_fuzzy_on_reward_edge_overflow() {
        reward_fuzzing(RANGE_MAX_U64-1, RANGE_MAX_U64, 1, 1 * E4C_DECIMALS, 100 * E4C_DECIMALS, 51240955760304);
    }


    #[test]
    fun test_manual_fuzzy_on_reward_edge_MAX_U16() {
        reward_fuzzing(10_000 * E4C_DECIMALS, 360, RANGE_MAX_U16, 1 * E4C_DECIMALS, 10000 * E4C_DECIMALS, RANGE_MAX_U16 as u64 * E4C_DECIMALS);
    }

    fun return_all(
        scenario: &ts::Scenario,
        staking_config: StakingConfig,
        cap: AdminCap,
        clock: sui::clock::Clock,
    ){
        ts::return_shared(staking_config);
        scenario.return_to_sender(cap);
        clock.destroy_for_testing();
    }

    fun add_staking_rule_for_testing(
        scenario: &mut ts::Scenario,
        staking_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64,
    ): (StakingConfig, AdminCap, sui::clock::Clock) {
        let mut staking_config: StakingConfig = scenario.take_shared();
        let clock = clock::create_for_testing(scenario.ctx());
        let cap: AdminCap = scenario.take_from_sender();

        config::add_staking_rule(&cap, 
                                    &mut staking_config, 
                                    staking_time, 
                                    annualized_interest_rate_bp,
                                    staking_quantity_range_min,
                                    staking_quantity_range_max,
                                    &clock
                                    );
        (staking_config, cap, clock)
    }

    fun init_and_add_rule(
        test_address: address,
        stake_time: u64,
        annualized_interest_rate_bp: u16,
        staking_quantity_range_min: u64,
        staking_quantity_range_max: u64,

    ){
        let mut scenario = ts::begin(test_address);
        {
            config::init_for_testing(scenario.ctx());
        };

        ts::next_tx(&mut scenario, test_address);
        {   
            let(staking_config, cap, clock) = add_staking_rule_for_testing(
                                        &mut scenario, 
                                        stake_time, 
                                        annualized_interest_rate_bp, 
                                        staking_quantity_range_min, 
                                        staking_quantity_range_max
                                        );
            return_all(&scenario, staking_config, cap, clock);
        };
        scenario.end();

    }

    #[test]
    fun test_add_new_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        {
            config::init_for_testing(scenario.ctx());
        };

        ts::next_tx(&mut scenario, @ambrus);
        {   
            let(staking_config, cap, clock) = add_staking_rule_for_testing(
                                        &mut scenario, 
                                        NEW_STAKING_TIME, 
                                        NEW_ANNUALIZED_INTEREST_RATE_BP, NEW_STAKING_QUANTITY_RANGE_MIN, NEW_STAKING_QUANTITY_RANGE_MAX);

            //Need to add check new staking rule
            let new_staking_rule = staking_config.get_staking_rule(NEW_STAKING_TIME);
            let (expected_range_min, expected_range_max) = new_staking_rule.staking_quantity_range();
            assert_eq(expected_range_min, NEW_STAKING_QUANTITY_RANGE_MIN);
            assert_eq(expected_range_max, NEW_STAKING_QUANTITY_RANGE_MAX);
            assert_eq(new_staking_rule.annualized_interest_rate_bp(), NEW_ANNUALIZED_INTEREST_RATE_BP);
            assert_eq(staking_config.staking_reward(NEW_STAKING_TIME, STAKING_AMOUNT),  
                        PRE_CALCULATION_STAKING_REWARD);
            
            return_all(&scenario, staking_config, cap, clock);
        };
        scenario.end();

    }

    #[test]
    #[expected_failure(abort_code = EStakingTimeMustBeGreaterThanZero)]
    fun test_add_new_staking_rule_with_zero_staking_time() {
        init_and_add_rule(@ambrus, 
                    0, 
                    NEW_ANNUALIZED_INTEREST_RATE_BP, 
                    NEW_STAKING_QUANTITY_RANGE_MIN, 
                    NEW_STAKING_QUANTITY_RANGE_MAX)
    }

    #[test]
    #[expected_failure(abort_code = EIncorrectBasisPoints)]
    fun test_add_new_staking_rule_with_incorrect_basis_points() {
        init_and_add_rule(@ambrus, 
                    NEW_STAKING_TIME, 
                    MAX_BPS+1, 
                    NEW_STAKING_QUANTITY_RANGE_MIN, 
                    NEW_STAKING_QUANTITY_RANGE_MAX)
    }

    #[test]
    #[expected_failure(abort_code = EStakingQuantityRangeUnmatch)]
    fun test_add_new_staking_rule_with_unmatch_staking_quantity_range() {
        init_and_add_rule(@ambrus, 
                    NEW_STAKING_TIME, 
                    NEW_ANNUALIZED_INTEREST_RATE_BP, 
                    NEW_STAKING_QUANTITY_RANGE_MAX, 
                    NEW_STAKING_QUANTITY_RANGE_MIN)
    }

    #[test]
    #[expected_failure(abort_code = EStakingTimeConflict)]
    fun test_add_new_staking_rule_with_conflict_staking_time() {
        let mut scenario = ts::begin(@ambrus);
        {
            config::init_for_testing(scenario.ctx());
        };

        ts::next_tx(&mut scenario, @ambrus);
        {   
            let(mut staking_config, cap, clock) = add_staking_rule_for_testing(
                                        &mut scenario, 
                                        NEW_STAKING_TIME, 
                                        NEW_ANNUALIZED_INTEREST_RATE_BP, 
                                        NEW_STAKING_QUANTITY_RANGE_MIN, 
                                        NEW_STAKING_QUANTITY_RANGE_MAX
                                        );
            config::add_staking_rule(&cap, 
                                    &mut staking_config, 
                                    NEW_STAKING_TIME, 
                                    NEW_ANNUALIZED_INTEREST_RATE_BP,
                                    NEW_STAKING_QUANTITY_RANGE_MIN,
                                    NEW_STAKING_QUANTITY_RANGE_MAX,
                                    &clock
                                    );
            return_all(&scenario, staking_config, cap, clock);
        };
        scenario.end();
    }

    #[test]
    fun test_check_details_removed_existing_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        ts::next_tx(&mut scenario, @ambrus);
        {
            config::init_for_testing(scenario.ctx());
        };

        ts::next_tx(&mut scenario, @ambrus);      
        {   
            let mut staking_config: StakingConfig = scenario.take_shared();
            let clock = clock::create_for_testing(scenario.ctx());
            let cap: AdminCap = scenario.take_from_sender();
            let removed = cap.remove_staking_rule(&mut staking_config, 
                                                TARGETED_REMOVE_STAKING_TIME, 
                                                &clock);
            
            let (removed_ranges_min, removed_range_max) = removed.staking_quantity_range();

            assert_eq(removed_ranges_min, REMOVING_STAKING_QUANTITY_RANGE_MIN * E4C_DECIMALS);
            assert_eq(removed_range_max, RANGE_MAX_U64);
            assert_eq(removed.annualized_interest_rate_bp(), REMOVING_ANNUALIZED_INTEREST_RATE_BP);
            
            return_all(&scenario, staking_config, cap, clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EStakingTimeNotFound)]
    fun test_remove_existing_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        ts::next_tx(&mut scenario, @ambrus);
        {
            config::init_for_testing(scenario.ctx());
        };

        ts::next_tx(&mut scenario, @ambrus);
        
        {   
            let mut staking_config: StakingConfig = scenario.take_shared();
            let clock = clock::create_for_testing(scenario.ctx());
            let cap: AdminCap = scenario.take_from_sender();
            let staking_time = 30;
            
            cap.remove_staking_rule(&mut staking_config, staking_time, &clock);
            staking_config.get_staking_rule(staking_time);
            return_all(&scenario, staking_config, cap, clock);
        };
        scenario.end();
    }
}
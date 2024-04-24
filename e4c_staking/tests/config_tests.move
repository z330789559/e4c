#[test_only]
module e4c_staking::config_tests {
    use sui::clock::{Self};
    use sui::test_utils::{assert_eq, destroy};
    use sui::test_scenario as ts;

    use e4c_staking::config::{AdminCap, StakingConfig, Self};
    const NEW_STAKING_TIME: u64 = 300;
    const NEW_ANNUALIZED_INTEREST_RATE_BP: u16 = 3610;
    const NEW_STAKING_QUANTITY_RANGE_MIN: u64 = 3620;
    const NEW_STAKING_QUANTITY_RANGE_MAX: u64 = 36300;
    const STAKING_AMOUNT: u64 = 3620;
    const PRE_CALCULATION_STAKING_REWARD: u64 = 1088;
    
    const TARGETED_REMOVE_STAKING_TIME: u64 = 90;
    const REMOVING_STAKING_QUANTITY_RANGE_MIN: u64 = 1000;
    const REMOVING_ANNUALIZED_INTEREST_RATE_BP: u16 = 3000;

    const RANGE_MAX_U64: u64 = 18446744073709551615;
    const RANGE_MAX_U16: u16 = 65535;

    // ADD STAKING RULE CASES NO.1
    // stake_time: 30 days
    // annualized_interest_rate_bp: 1000 : 10%
    // staking_quantity_range_min: 1
    // staking_quantity_range_max: 100
    #[test]
    fun test_manual_fuzzy_on_reward_1() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (100, 30, 1000, 1, 100, 0);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }

    // ADD STAKING RULE CASES NO.2
    // stake_time: 60 days
    // annualized_interest_rate_bp: 2000 : 20%
    // staking_quantity_range_min: 100
    // staking_quantity_range_max: 1000
    #[test]
    fun test_manual_fuzzy_on_reward_2() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (1000, 60, 2000, 100, 1000, 33);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }

    // ADD STAKING RULE CASES NO.3
    // stake_time: 90 days
    // annualized_interest_rate_bp: 3000 : 30%
    // staking_quantity_range_min: 3000
    // staking_quantity_range_max: 18446744073709551615 : MAX_U64
    #[test]
    fun test_manual_fuzzy_on_reward_3() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (3000, 90, 3000, 3000, RANGE_MAX_U64, 225);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }
    
    // ADD STAKING RULE EDGE CASES NO.1
    // stake_time: 360 day
    // annualized_interest_rate_bp: 1 : 0.01%
    #[test]
    fun test_manual_fuzzy_on_reward_MAX_U64_1() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (RANGE_MAX_U64, 360, 1, 3000, RANGE_MAX_U64, 1844674407370955);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }

    // ADD STAKING RULE EDGE CASES NO.2
    // stake_time: 359 day
    // annualized_interest_rate_bp: 1 : 0.01%
    #[test]
    fun test_error_manual_fuzzy_on_reward_MAX_U64_2() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (RANGE_MAX_U64, 359, 1, 3000, RANGE_MAX_U64, 0);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }
    
    // ADD STAKING RULE EDGE CASES NO.3
    // stake_time: RANGE_MAX_U64 day
    // annualized_interest_rate_bp: 1 : 0.01%

    #[test]
    fun test_manual_fuzzy_on_reward_edge() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (1, RANGE_MAX_U64, 1, 1, 100, 5124095576030);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }

    // failed to overflow u64
    #[test]
    #[expected_failure]
    fun test_manual_fuzzy_on_reward_edge_overflow() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (RANGE_MAX_U64-1, RANGE_MAX_U64, 1, 1, 100, 51240955760304);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }


    #[test]
    fun test_manual_fuzzy_on_reward_edge_MAX_U16() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (10000, 360, RANGE_MAX_U16, 1, 10000, RANGE_MAX_U16 as u64);
        let details = config::new_staking_rules(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::staking_reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);

        destroy(config);
    }


    #[test]
    fun test_add_new_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        {
            config::init_for_testing(ts::ctx(&mut scenario));
        };

        ts::next_tx(&mut scenario, @ambrus);
        {   
            let mut staking_config: StakingConfig = ts::take_shared(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let cap: AdminCap = ts::take_from_sender(&scenario);
            config::add_staking_rule(&cap, 
                                    &mut staking_config, 
                                    NEW_STAKING_TIME, 
                                    NEW_ANNUALIZED_INTEREST_RATE_BP,
                                    NEW_STAKING_QUANTITY_RANGE_MIN,
                                    NEW_STAKING_QUANTITY_RANGE_MAX,
                                    &clock
                                    );
            //Need to add check new staking rule
            let new_staking_rule = config::get_staking_rule(&staking_config, NEW_STAKING_TIME);
            let (expected_range_min, expected_range_max) = config::staking_quantity_range(new_staking_rule);
            let expected_annual_interest = config::annualized_interest_rate_bp(new_staking_rule);
            let expected_reward = config::staking_reward(&staking_config, NEW_STAKING_TIME, STAKING_AMOUNT);
            assert_eq(expected_range_min, NEW_STAKING_QUANTITY_RANGE_MIN);
            assert_eq(expected_range_max, NEW_STAKING_QUANTITY_RANGE_MAX);
            assert_eq(expected_annual_interest, NEW_ANNUALIZED_INTEREST_RATE_BP);
            assert_eq(expected_reward, PRE_CALCULATION_STAKING_REWARD);
            
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
            clock::destroy_for_testing(clock);
        };
        ts::end(scenario);

    }

    #[test]
    fun test_check_details_removed_existing_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        ts::next_tx(&mut scenario, @ambrus);
        {
            config::init_for_testing(ts::ctx(&mut scenario));
        };

        ts::next_tx(&mut scenario, @ambrus);      
        {   
            let mut staking_config: StakingConfig = ts::take_shared(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let cap: AdminCap = ts::take_from_sender(&scenario);
            let removed = config::remove_staking_rule(&cap, &mut staking_config, TARGETED_REMOVE_STAKING_TIME, &clock);
            
            let (removed_ranges_min, removed_range_max) = config::staking_quantity_range(&removed);
            let removed_annual_interest = config::annualized_interest_rate_bp(&removed);

            assert_eq(removed_ranges_min, REMOVING_STAKING_QUANTITY_RANGE_MIN);
            assert_eq(removed_range_max, RANGE_MAX_U64);
            assert_eq(removed_annual_interest, REMOVING_ANNUALIZED_INTEREST_RATE_BP);
            
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
            clock::destroy_for_testing(clock);
        };
        ts::end(scenario);
    }

    #[test,expected_failure(abort_code = e4c_staking::config::EStakingTimeNotFound)]
    fun test_remove_existing_staking_rule() {
        let mut scenario = ts::begin(@ambrus);
        ts::next_tx(&mut scenario, @ambrus);
        {
            config::init_for_testing(ts::ctx(&mut scenario));
        };

        ts::next_tx(&mut scenario, @ambrus);
        
        {   
            let mut staking_config: StakingConfig = ts::take_shared(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let cap: AdminCap = ts::take_from_sender(&scenario);
            let staking_time = 30;
            
            config::remove_staking_rule(&cap, &mut staking_config, staking_time, &clock);
            config::get_staking_rule(&staking_config, staking_time);
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
            clock::destroy_for_testing(clock);
        };
        ts::end(scenario);
    }

}

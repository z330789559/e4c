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
    const PRE_CALCULATION_STAKING_REWARD: u64 = 10888;
    
    const TARGETED_REMOVE_STAKING_TIME: u64 = 90;
    const REMOVING_STAKING_QUANTITY_RANGE_MIN: u64 = 1000;
    const REMOVING_STAKING_QUANTITY_RANGE_MAX: u64 = 18446744073709551615;
    const REMOVING_ANNUALIZED_INTEREST_RATE_BP: u16 = 3000;
    #[test]
    fun test_reward() {
        let mut ctx = tx_context::dummy();
        let (staking_quantity,
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max,
            expected_reward
        ) = (100, 30, 1000, 1, 100, 8);
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
            assert_eq(removed_range_max, REMOVING_STAKING_QUANTITY_RANGE_MAX);
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

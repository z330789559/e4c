#[test_only]
module e4c_staking::config_tests {
    use sui::test_utils::{assert_eq, destroy};
    use sui::test_scenario as ts;

    use e4c_staking::config::{AdminCap, StakingConfig, Self};

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
            let cap: AdminCap = ts::take_from_sender(&scenario);
            let new_staking_time = 300;
            let new_annualized_interest_rate_bp = 3610;
            let new_staking_quantity_range_min = 3620;
            let new_staking_quantity_range_max = 36300;
            let staking_amount = 3620;
            let pre_calculation_staking_reward =10888;
            config::add_staking_rule(&cap, 
                                    &mut staking_config, 
                                    new_staking_time, 
                                    new_annualized_interest_rate_bp, 
                                    new_staking_quantity_range_min, 
                                    new_staking_quantity_range_max
                                    );
            //Need to add check new staking rule
            let new_staking_rule = config::get_staking_rule(&staking_config, new_staking_time);
            let (expected_range_min, expected_range_max) = config::staking_quantity_range(new_staking_rule);
            let expected_annual_interest = config::annualized_interest_rate_bp(new_staking_rule);
            let expected_reward = config::staking_reward(&staking_config, new_staking_time, staking_amount);
            assert_eq(expected_range_min, new_staking_quantity_range_min);
            assert_eq(expected_range_max, new_staking_quantity_range_max);
            assert_eq(expected_annual_interest, new_annualized_interest_rate_bp);
            assert_eq(expected_reward, pre_calculation_staking_reward);
            
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
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
            let cap: AdminCap = ts::take_from_sender(&scenario);
            let staking_time = 90;
            let removing_range_min_value = 1000;
            let removing_range_max_value = 18446744073709551615;
            let removing_annual_interest = 3000;
            let removed = config::remove_staking_rule(&cap, &mut staking_config, staking_time);
            
            let (removed_ranges_min, removed_range_max) = config::staking_quantity_range(&removed);
            let removed_annual_interest = config::annualized_interest_rate_bp(&removed);
            assert_eq(removed_ranges_min, removing_range_min_value);
            assert_eq(removed_range_max, removing_range_max_value);
            assert_eq(removed_annual_interest, removing_annual_interest);
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
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
            let cap: AdminCap = ts::take_from_sender(&scenario);
            let staking_time = 30;
            
            config::remove_staking_rule(&cap, &mut staking_config, staking_time);
            config::get_staking_rule(&staking_config, staking_time);
            ts::return_shared(staking_config);
            ts::return_to_sender(&scenario,cap);
        };
        ts::end(scenario);
    }

}

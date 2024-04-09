#[test_only]
module e4c::config_tests {
    use sui::test_utils::{assert_eq, destroy};
    use sui::tx_context;
    
    use e4c::config;
    
    #[test]
    fun test_reward() {
        let ctx = tx_context::dummy();
        let (staking_quantity, staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max, expected_reward) = (100, 30, 1000, 1, 100, 8);
        let details = config::new_staking_details(
            staking_time,
            annualized_interest_rate_bp,
            staking_quantity_range_min,
            staking_quantity_range_max
        );
        let config = config::new_staking_config(details, staking_time, &mut ctx);
        let reward = config::reward(&config, staking_time, staking_quantity);
        assert_eq(reward, expected_reward);
        
        destroy(config);
    }
}

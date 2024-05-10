#[test_only]
module e4c_staking::overlapping_tests {
    use sui::{
        clock::{Self},
        test_utils::{assert_eq},
        test_scenario as ts,
    };
    use e4c_staking::config::{Self, AdminCap, StakingConfig};

    const E4C_DECIMALS: u64 = 100;
    const MAX_U64: u64 = 18446744073709551615;

    #[test]
    fun is_amount_overlapping() {
        let mut scenario = ts::begin(@ambrus);
        config::init_for_testing(scenario.ctx());
        scenario.next_tx(@ambrus); // with original config
        {
            let staking_config: StakingConfig = scenario.take_shared();

            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 0), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 1, 99), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 1 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 100_000 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 99, 1 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 100 * E4C_DECIMALS, 101 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 300 * E4C_DECIMALS, 100_000 * E4C_DECIMALS), true);

            ts::return_shared(staking_config);
        };
        scenario.next_tx(@ambrus);
        {
            let admin_cap = scenario.take_from_sender<AdminCap>();
            let mut staking_config: StakingConfig = scenario.take_shared();
            let clock = clock::create_for_testing(scenario.ctx());

            // remove 90 days rule
            config::remove_staking_rule(&admin_cap, &mut staking_config, 90, &clock);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 0), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 1, 99), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 1000 * E4C_DECIMALS, MAX_U64), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, MAX_U64, MAX_U64), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 1 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 100_000 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 99, 1 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 100 * E4C_DECIMALS, 101 * E4C_DECIMALS), true);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 300 * E4C_DECIMALS, 100_000 * E4C_DECIMALS), true);

            // remove 30 and 60 days rule and make rules empty
            config::remove_staking_rule(&admin_cap, &mut staking_config, 30, &clock);
            config::remove_staking_rule(&admin_cap, &mut staking_config, 60, &clock);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, 0), false);
            assert_eq(config::is_amount_overlapping_for_testing(&staking_config, 0, MAX_U64), false);

            scenario.return_to_sender(admin_cap);
            ts::return_shared(staking_config);
            clock::destroy_for_testing(clock);
        };
        scenario.end();
    }
}

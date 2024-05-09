#[test_only]
module e4c_staking::reward_30_days_tests {
    use sui::{
        test_utils::{assert_eq},
        test_scenario as ts,
        test_scenario::{Scenario},
    };

    use e4c_staking::staking::{StakingReceipt};
    use e4c_staking::config::{ StakingConfig};
    
    use e4c_staking::staking_tests::{Self};

    // Simulation sheets : https://docs.google.com/spreadsheets/d/1ScREAb0ueIC8Ml5RaQTEtWzUgAWj28KUqBV16gdiF3U/edit?usp=sharing
    const E4C_DECIMALS: u64 = 1_000_000_000;
    const E4CTokenMaxSupply: u64 = 1_000_000_000 * E4C_DECIMALS;
    // const ROI_30_DAYS : u64 = 67;

    const SIMULATION_1_AMOUNT: u64 = 1_000_000_000;
    const REWARD_EXPECTED_1: u64 = 6_700_000;

    const SIMULATION_2_AMOUNT: u64 = 1197847582;
    const REWARD_EXPECTED_2: u64 = 8025579;

    const SIMULATION_3_AMOUNT: u64 = 1287689108;
    const REWARD_EXPECTED_3: u64 = 8627517;
    
    const SIMULATION_4_AMOUNT: u64 = 2285661699;
    const REWARD_EXPECTED_4: u64 = 15313933;

    const SIMULATION_5_AMOUNT: u64 = 10123456789;
    const REWARD_EXPECTED_5: u64 = 67827160;
    
    const SIMULATION_6_AMOUNT: u64 = 10018927561;
    const REWARD_EXPECTED_6: u64 = 67126815;

    const SIMULATION_7_AMOUNT: u64 = 11982638501;
    const REWARD_EXPECTED_7: u64 = 80283678;
    
    const SIMULATION_8_AMOUNT: u64 = 15783615589;
    const REWARD_EXPECTED_8: u64 = 105750224;
    
    const SIMULATION_9_AMOUNT: u64 = 10828759091;
    const REWARD_EXPECTED_9: u64 = 72552686;
    
    const SIMULATION_10_AMOUNT: u64 = 10927856100;
    const REWARD_EXPECTED_10: u64 = 73216636;
    
    const SIMULATION_11_AMOUNT: u64 = 30897968600;
    const REWARD_EXPECTED_11: u64 = 207016390;
    
    const SIMULATION_12_AMOUNT: u64 = 32343468789;
    const REWARD_EXPECTED_12: u64 = 216701241;
    
    const SIMULATION_13_AMOUNT: u64 = 42598769261;
    const REWARD_EXPECTED_13: u64 = 285411754;

    const SIMULATION_14_AMOUNT: u64 = 55999373619;
    const REWARD_EXPECTED_14: u64 = 375195803;

    const SIMULATION_15_AMOUNT: u64 = 99990090091;
    const REWARD_EXPECTED_15: u64 = 669933604;

    const SIMULATION_16_AMOUNT: u64 = 90165737372;
    const REWARD_EXPECTED_16: u64 = 604110440;

    const SIMULATION_17_AMOUNT: u64 = 98910000000;
    const REWARD_EXPECTED_17: u64 = 662697000;

    const SIMULATION_18_AMOUNT: u64 = 100000000000;
    const REWARD_EXPECTED_18: u64 = 670000000;

    const TEST_BALANCE: u64 = 100_000 * E4C_DECIMALS;
    
    
    fun scenario(): Scenario { ts::begin(@0x1) }

    fun day30_initiation(
        scenario: &mut Scenario,
        simulation_amount: u64,
    ){
            staking_tests::init_and_gen_staking_receipt(
            @alice,
            E4CTokenMaxSupply,
            TEST_BALANCE,
            simulation_amount,
            30,
            0,
            scenario
        );
    }

    fun days30_test_fun(
        scenario: &Scenario,
        amount: u64,
        expected_reward: u64,
    ) {
        let config = scenario.take_shared<StakingConfig>();
        let receipt_obj = scenario.take_from_sender<StakingReceipt>();
        let reward = config.staking_reward(30, amount);
        let requested_amount_from_pool = receipt_obj.staking_receipt_reward();
        assert_eq(reward, requested_amount_from_pool);
        assert_eq(expected_reward, requested_amount_from_pool);
        assert_eq(expected_reward, reward);
        
        ts::return_shared(config);
        scenario.return_to_sender(receipt_obj);
    }
    #[test]
    fun day30_test_01() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_1_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_1_AMOUNT, REWARD_EXPECTED_1);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_2() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_2_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_2_AMOUNT, REWARD_EXPECTED_2);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_3() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_3_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_3_AMOUNT, REWARD_EXPECTED_3);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_4() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_4_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_4_AMOUNT, REWARD_EXPECTED_4);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_5() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_5_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_5_AMOUNT, REWARD_EXPECTED_5);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_6() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_6_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_6_AMOUNT, REWARD_EXPECTED_6);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_7() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_7_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_7_AMOUNT, REWARD_EXPECTED_7);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_8() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_8_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_8_AMOUNT, REWARD_EXPECTED_8);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_9() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_9_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_9_AMOUNT, REWARD_EXPECTED_9);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_10() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_10_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_10_AMOUNT, REWARD_EXPECTED_10);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_11() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_11_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_11_AMOUNT, REWARD_EXPECTED_11);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_12() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_12_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_12_AMOUNT, REWARD_EXPECTED_12);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_13() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_13_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_13_AMOUNT, REWARD_EXPECTED_13);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_14() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_14_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_14_AMOUNT, REWARD_EXPECTED_14);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_15() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_15_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_15_AMOUNT, REWARD_EXPECTED_15);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_16() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_16_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_16_AMOUNT, REWARD_EXPECTED_16);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_17() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_17_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_17_AMOUNT, REWARD_EXPECTED_17);
        };

        scenario.end();
    }

    #[test]
    fun day30_test_18() {
        let mut scenario = scenario();
        day30_initiation(&mut scenario, SIMULATION_18_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days30_test_fun(&scenario, SIMULATION_18_AMOUNT, REWARD_EXPECTED_18);
        };

        scenario.end();
    }


}
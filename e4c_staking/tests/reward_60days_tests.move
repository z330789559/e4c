#[test_only]
module e4c_staking::reward_60_days_tests {
    use sui::{
        test_utils::{assert_eq},
        test_scenario as ts,
        test_scenario::{Scenario},
    };

    use e4c_staking::staking::{StakingReceipt};
    use e4c_staking::config::{ StakingConfig};
    
    use e4c_staking::staking_tests::{Self};

    // Simulation sheets : https://docs.google.com/spreadsheets/d/1ScREAb0ueIC8Ml5RaQTEtWzUgAWj28KUqBV16gdiF3U/edit?usp=sharing
    const E4CTokenMaxSupply: u64 = 1_000_000_000_00;
    const TEST_BALANCE: u64 = 100_000; // 1_000 E4C

    const SIMULATION_1_AMOUNT: u64 = 10019;
    const SIMULATION_1_EXPECTED_REWARD: u64 = 167;

    const SIMULATION_2_AMOUNT: u64 = 10030;
    const SIMULATION_2_EXPECTED_REWARD: u64 = 168;

    const SIMULATION_3_AMOUNT: u64 = 10001;
    const SIMULATION_3_EXPECTED_REWARD: u64 = 167;

    const SIMULATION_4_AMOUNT: u64 = 10056;
    const SIMULATION_4_EXPECTED_REWARD: u64 = 168;

    const SIMULATION_5_AMOUNT: u64 = 10070;
    const SIMULATION_5_EXPECTED_REWARD: u64 = 168;

    const SIMULATION_6_AMOUNT: u64 = 10088;
    const SIMULATION_6_EXPECTED_REWARD: u64 = 168;

    const SIMULATION_7_AMOUNT: u64 = 10095;
    const SIMULATION_7_EXPECTED_REWARD: u64 = 169;

    const SIMULATION_8_AMOUNT: u64 = 32554;
    const SIMULATION_8_EXPECTED_REWARD: u64 = 544;

    const SIMULATION_9_AMOUNT: u64 = 40890;
    const SIMULATION_9_EXPECTED_REWARD: u64 = 683;

    const SIMULATION_10_AMOUNT: u64 = 50091;
    const SIMULATION_10_EXPECTED_REWARD: u64 = 837;

    const SIMULATION_11_AMOUNT: u64 = 62365;
    const SIMULATION_11_EXPECTED_REWARD: u64 = 1041;

    const SIMULATION_12_AMOUNT: u64 = 80008;
    const SIMULATION_12_EXPECTED_REWARD: u64 = 1336;

    const SIMULATION_13_AMOUNT: u64 = 90098;
    const SIMULATION_13_EXPECTED_REWARD: u64 = 1505;

    const SIMULATION_14_AMOUNT: u64 = 99999;
    const SIMULATION_14_EXPECTED_REWARD: u64 = 1670;

    const SIMULATION_15_AMOUNT: u64 = 99910;
    const SIMULATION_15_EXPECTED_REWARD: u64 = 1668;

    const SIMULATION_16_AMOUNT: u64 = 99901;
    const SIMULATION_16_EXPECTED_REWARD: u64 = 1668;

    const SIMULATION_17_AMOUNT: u64 = 100000;
    const SIMULATION_17_EXPECTED_REWARD: u64 = 1670;

    fun scenario(): Scenario { ts::begin(@0x1) }
    fun day60_initiation(
        scenario: &mut Scenario,
        simulation_amount: u64,
    ){
            staking_tests::init_and_gen_staking_receipt(
            @alice,
            E4CTokenMaxSupply,
            TEST_BALANCE,
            simulation_amount,
            60,
            0,
            scenario
        );
    }

    fun days60_test_fun(
        scenario: &Scenario,
        amount: u64,
        expected_reward: u64,
    ) {
        let config = scenario.take_shared<StakingConfig>();
        let receipt_obj = scenario.take_from_sender<StakingReceipt>();
        let reward = config.staking_reward(60, amount);
        let requested_amount_from_pool = receipt_obj.staking_receipt_reward();
        assert_eq(reward, requested_amount_from_pool);
        assert_eq(expected_reward, requested_amount_from_pool);
        assert_eq(expected_reward, reward);
        
        ts::return_shared(config);
        scenario.return_to_sender(receipt_obj);
    }

    #[test]
     fun day60_test_1() {
         let mut scenario = scenario();
         day60_initiation(&mut scenario, SIMULATION_1_AMOUNT);
         ts::next_tx(&mut scenario, @alice);
         {
             days60_test_fun(&scenario, SIMULATION_1_AMOUNT, SIMULATION_1_EXPECTED_REWARD);
         };
        scenario.end();
     }

    #[test]
    fun day60_test_2() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_2_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_2_AMOUNT, SIMULATION_2_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_3() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_3_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_3_AMOUNT, SIMULATION_3_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_4() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_4_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_4_AMOUNT, SIMULATION_4_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_5() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_5_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_5_AMOUNT, SIMULATION_5_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_6() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_6_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_6_AMOUNT, SIMULATION_6_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_7() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_7_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_7_AMOUNT, SIMULATION_7_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_8() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_8_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_8_AMOUNT, SIMULATION_8_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_9() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_9_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_9_AMOUNT, SIMULATION_9_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_10() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_10_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_10_AMOUNT, SIMULATION_10_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_11() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_11_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_11_AMOUNT, SIMULATION_11_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_12() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_12_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_12_AMOUNT, SIMULATION_12_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_13() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_13_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_13_AMOUNT, SIMULATION_13_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_14() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_14_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_14_AMOUNT, SIMULATION_14_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_15() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_15_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_15_AMOUNT, SIMULATION_15_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_16() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_16_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_16_AMOUNT, SIMULATION_16_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun day60_test_17() {
        let mut scenario = scenario();
        day60_initiation(&mut scenario, SIMULATION_17_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days60_test_fun(&scenario, SIMULATION_17_AMOUNT, SIMULATION_17_EXPECTED_REWARD);
        };
        scenario.end();
    }

}
#[test_only]

module e4c_staking::reward_90_days_tests {
    use sui::{
        test_utils::{assert_eq},
        test_scenario as ts,
        test_scenario::{Scenario},
    };

    use e4c_staking::staking::{StakingReceipt};
    use e4c_staking::config::{ StakingConfig};
    
    use e4c_staking::staking_tests::{Self};

    // Simulation sheets : https://docs.google.com/spreadsheets/d/1ScREAb0ueIC8Ml5RaQTEtWzUgAWj28KUqBV16gdiF3U/edit?usp=sharing
    // Delta from NO 18, No 20, Please take a look at the sheet for checking correct number of reward. 
   const E4C_DECIMALS: u64 = 1_000_000_000;
    const E4CTokenMaxSupply: u64 = 1_000_000_000 * E4C_DECIMALS;

    const SIMULATION_1_AMOUNT: u64 = 1000_287_590_176;
    const SIMULATION_1_EXPECTED_REWARD: u64 = 37_510_784_632;

    const SIMULATION_2_AMOUNT: u64 = 1000_189_999_990;
    const SIMULATION_2_EXPECTED_REWARD: u64 = 37_507_125_000;

    const SIMULATION_3_AMOUNT: u64 = 1000_229_761_967;
    const SIMULATION_3_EXPECTED_REWARD: u64 = 37_508_616_074;

    const SIMULATION_4_AMOUNT: u64 = 1000_586_609_167;
    const SIMULATION_4_EXPECTED_REWARD: u64 = 37_521_997_844;

    const SIMULATION_5_AMOUNT: u64 = 1000_488_715_692;
    const SIMULATION_5_EXPECTED_REWARD: u64 = 37_518_326_838;

    const SIMULATION_6_AMOUNT: u64 = 1000_678_999_990;
    const SIMULATION_6_EXPECTED_REWARD: u64 = 37_525_462_500;

    const SIMULATION_7_AMOUNT: u64 = 2000_149_191_977;
    const SIMULATION_7_EXPECTED_REWARD: u64 = 75_005_594_699;

    const SIMULATION_8_AMOUNT: u64 = 10000_010_101_010;
    const SIMULATION_8_EXPECTED_REWARD: u64 = 375_000_378_788;

    const SIMULATION_9_AMOUNT: u64 = 10000_999_808_081;
    const SIMULATION_9_EXPECTED_REWARD: u64 = 375_037_492_803;

    const SIMULATION_10_AMOUNT: u64 = 100000_118_765_564;
    const SIMULATION_10_EXPECTED_REWARD: u64 = 3750_004_453_709;

    const SIMULATION_11_AMOUNT: u64 = 100000_989_898_799;
    const SIMULATION_11_EXPECTED_REWARD: u64 = 3750_037_121_205;

    const SIMULATION_12_AMOUNT: u64 = 1000000019999990;
    const SIMULATION_12_EXPECTED_REWARD: u64 = 37500000750000;

    const SIMULATION_13_AMOUNT: u64 = 1000001679000290;
    const SIMULATION_13_EXPECTED_REWARD: u64 = 37500062962511;

    const SIMULATION_14_AMOUNT: u64 = 10000000010101000;
    const SIMULATION_14_EXPECTED_REWARD: u64 = 375000000378788;

    const SIMULATION_15_AMOUNT: u64 = 10000000280000000;
    const SIMULATION_15_EXPECTED_REWARD: u64 = 375000010500000;

    const SIMULATION_16_AMOUNT: u64 = 10000000780000000;
    const SIMULATION_16_EXPECTED_REWARD: u64 = 375000029250000;

    const SIMULATION_17_AMOUNT: u64 = 10000000340000000;
    const SIMULATION_17_EXPECTED_REWARD: u64 = 375000012750000;

    const SIMULATION_18_AMOUNT: u64 = 99999999898987800;
    const SIMULATION_18_EXPECTED_REWARD: u64 = 3749999996212043;

    const SIMULATION_19_AMOUNT: u64 = 99999999990000000;
    const SIMULATION_19_EXPECTED_REWARD: u64 = 3749999999625000;

    const SIMULATION_20_AMOUNT: u64 = 99999999410000000;
    const SIMULATION_20_EXPECTED_REWARD: u64 = 3749999977875000;

    const SIMULATION_21_AMOUNT: u64 = 99999999119989700;
    const SIMULATION_21_EXPECTED_REWARD: u64 = 3749999966999614;

    const SIMULATION_22_AMOUNT: u64 = 970123123098768799;
    const SIMULATION_22_EXPECTED_REWARD: u64 = 36379617116203830;

    fun scenario(): Scenario { ts::begin(@0x1) }
    fun days90_initiation(
        scenario: &mut Scenario,
        simulation_amount: u64,
    ){
            staking_tests::init_and_gen_staking_receipt(
            @alice,
            E4CTokenMaxSupply,
            E4CTokenMaxSupply,
            simulation_amount,
            90,
            0,
            scenario
        );
    }

    fun days90_test_fun(
        scenario: &Scenario,
        amount: u64,
        expected_reward: u64,
    ) {
        let config = scenario.take_shared<StakingConfig>();
        let receipt_obj = scenario.take_from_sender<StakingReceipt>();
        let reward = config.staking_reward(90, amount);
        let requested_amount_from_pool = receipt_obj.staking_receipt_reward();
        assert_eq(reward, requested_amount_from_pool);
        assert_eq(expected_reward, requested_amount_from_pool);
        assert_eq(expected_reward, reward);
        
        ts::return_shared(config);
        scenario.return_to_sender(receipt_obj);
    }

    #[test]
     fun day90_test_1() {
         let mut scenario = scenario();
         days90_initiation(&mut scenario, SIMULATION_1_AMOUNT);
         ts::next_tx(&mut scenario, @alice);
         {
             days90_test_fun(&scenario, SIMULATION_1_AMOUNT, SIMULATION_1_EXPECTED_REWARD);
         };
        scenario.end();
     }

    #[test]
    fun day90_test_2() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_2_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_2_AMOUNT, SIMULATION_2_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_3() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_3_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_3_AMOUNT, SIMULATION_3_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_4() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_4_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_4_AMOUNT, SIMULATION_4_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_5() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_5_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_5_AMOUNT, SIMULATION_5_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_6() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_6_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_6_AMOUNT, SIMULATION_6_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_7() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_7_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_7_AMOUNT, SIMULATION_7_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_8() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_8_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_8_AMOUNT, SIMULATION_8_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_9() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_9_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_9_AMOUNT, SIMULATION_9_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_10() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_10_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_10_AMOUNT, SIMULATION_10_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_11() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_11_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_11_AMOUNT, SIMULATION_11_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_12() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_12_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_12_AMOUNT, SIMULATION_12_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_13() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_13_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_13_AMOUNT, SIMULATION_13_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_14() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_14_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_14_AMOUNT, SIMULATION_14_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_15() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_15_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_15_AMOUNT, SIMULATION_15_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_16() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_16_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_16_AMOUNT, SIMULATION_16_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_17() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_17_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_17_AMOUNT, SIMULATION_17_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_18() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_18_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_18_AMOUNT, SIMULATION_18_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_19() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_19_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_19_AMOUNT, SIMULATION_19_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_20() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_20_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_20_AMOUNT, SIMULATION_20_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_21() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_21_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_21_AMOUNT, SIMULATION_21_EXPECTED_REWARD);
        };
        scenario.end();
    }

    #[test]
    fun days90_test_22() {
        let mut scenario = scenario();
        days90_initiation(&mut scenario, SIMULATION_22_AMOUNT);
        ts::next_tx(&mut scenario, @alice);
        {
            days90_test_fun(&scenario, SIMULATION_22_AMOUNT, SIMULATION_22_EXPECTED_REWARD);
        };
        scenario.end();
    }

}
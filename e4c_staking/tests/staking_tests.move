#[test_only]
module e4c_staking::staking_tests {
    use sui::{
        balance,
        coin,
        clock::{Self, Clock},
        test_utils::{assert_eq},
        test_scenario as ts,
        test_scenario::{Scenario},
    };

    use e4c_staking::staking::{Self, GameLiquidityPool, StakingReceipt, 
                        EStakingTimeNotEnded, EAmountMustBeGreaterThanZero, 
                        EAmountTooHigh, 
                        EStakingQuantityTooLow, EStakingQuantityTooHigh};
    use e4c_staking::config::{AdminCap, StakingConfig};
    use e4c::e4c::E4C;
    
    const CLOCK_SET_TIMESTAMP: u64 = 2024;
    const MILLIS_IN_90_DAYS: u64 = 7776000000;
    const MILLIS_IN_60_DAYS: u64 = 5184000000;

    const ALICE_BALANCE: u64 = 3_000;
    const ALICE_STAKED_AMOUNT : u64 = 2_000;
    const ALICE_STAKING_PERIOD: u64 = 90;

    const TOO_SMALL_STAKING_AMOUNT: u64 = 10;
    const TOO_LARGE_STAKING_AMOUNT: u64 = 4_000;

    const BOB_BALANCE: u64 = 300;
    const BOB_BALANCE_FOR_ERROR_TESTING: u64 = 5_000;
    const BOB_STAKED_AMOUNT : u64 = 100;
    const BOB_STAKING_PERIOD: u64 = 60;
    const ESTIMATED_REWARD_TO_BOB : u64 = 1;
    const ESTIMATED_INTEREST_RATE_ON_60_DAYS: u16 = 1000;

    const STRANGE_STAKING_PERIOD: u64 = 10_000;
    const STRANGE_INTEREST: u16 = 0;
    const STRANGE_STAKING_QUANTITY_MIN: u64 = 10_000;
    const STRANGE_STAKING_QUANTITY_MAX: u64 = 100_000;
    const ESTIMTED_REWARD_FROM_STRANGES : u64 = 0;
    const CHAD_BALANCE: u64 = 16_000;
    const CHAD_STAKED_AMOUNT : u64 = 12_000;

    const MINTING_AMOUNT: u64 = 100_000_000;
    const MINTING_SMALL : u64 = 10;

    const EXPECTED_GAME_LIQUIDITY_POOL_BALANCE: u64 = 10_000_000;
    const EXPECTED_REMAINING_PERIOD: u64 = 5183997976;


    fun return_and_destory_test_objects(
        pool: GameLiquidityPool,
        config: StakingConfig,
        clock: Clock,
    ) {
        ts::return_shared(pool);
        ts::return_shared(config);
        clock::destroy_for_testing(clock);
    }

    fun generate_staking_receipt_and_objects(
        current_balance: u64,
        staking_amount: u64,
        staking_in_days: u64,
        time_setting: u64,
        scenario: &mut Scenario,
    ): (StakingReceipt, GameLiquidityPool, StakingConfig, Clock) {
        let mut balance = balance::create_for_testing(current_balance);
        let stake = coin::take(&mut balance, staking_amount, scenario.ctx());    
        let mut clock = clock::create_for_testing(scenario.ctx());
        clock.set_for_testing(time_setting);
        let mut pool: GameLiquidityPool = scenario.take_shared();
        let config: StakingConfig = scenario.take_shared();
        
        let receipt_obj = staking::new_staking_receipt(
            stake, 
            &mut pool, 
            &clock,
            &config,
            staking_in_days,
            scenario.ctx()
        );
        balance.destroy_for_testing();
        (receipt_obj, pool, config, clock)
    }

    fun init_and_gen_staking_receipt(
        active_address: address,
        minting_amount: u64,
        current_balance: u64,
        staking_amount: u64,
        staking_period: u64,
        time_setting: u64,
        scenario: &mut Scenario,
    ) {
        ts::next_tx(scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                scenario,
                @treasury,
                minting_amount,
            )
        };
        ts::next_tx(scenario, active_address);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                current_balance,
                staking_amount,
                staking_period,
                time_setting,
                scenario
            );
            return_and_destory_test_objects(pool, config, clock);
            transfer::public_transfer(receipt_obj, active_address);
        };
    }
    

    #[test]
    fun test_calculation_locking_time() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @alice,
            MINTING_AMOUNT,
            ALICE_BALANCE,
            ALICE_STAKED_AMOUNT,
            ALICE_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @alice);
        {
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();
            let stake_end_time = received_staking_receipt.staking_receipt_staking_end_at();
            assert_eq(stake_end_time, CLOCK_SET_TIMESTAMP + MILLIS_IN_90_DAYS);
            scenario.return_to_sender(received_staking_receipt);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EStakingTimeNotEnded)]
    fun test_error_calculation_locking_time() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @alice,
            MINTING_AMOUNT,
            ALICE_BALANCE,
            ALICE_STAKED_AMOUNT,
            ALICE_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @alice);
        {
            let mut clock = clock::create_for_testing(scenario.ctx());
            clock.set_for_testing(CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();

            clock.increment_for_testing(MILLIS_IN_60_DAYS); // 5184000000 for 60 days 
            let reward_coin = received_staking_receipt.unstake(&clock, scenario.ctx());
            transfer::public_transfer(reward_coin, @alice);
            clock::destroy_for_testing(clock); 
        };

        scenario.end();
    }

    #[test]
    fun test_e4c_token_request() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @alice,
            MINTING_AMOUNT,
            ALICE_BALANCE,
            ALICE_STAKED_AMOUNT,
            ALICE_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @alice);
        {
            let config = scenario.take_shared<StakingConfig>();
            let receipt_obj = scenario.take_from_sender<StakingReceipt>();
            let get_expected_reward = config.staking_reward(ALICE_STAKING_PERIOD, ALICE_STAKED_AMOUNT);
            let requested_amount_from_pool = receipt_obj.staking_receipt_reward();
            assert_eq(get_expected_reward, requested_amount_from_pool);
            ts::return_shared(config);
            scenario.return_to_sender(receipt_obj);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EAmountMustBeGreaterThanZero)]
    fun test_error_amount_zero_e4c_token_request() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        // Add strange staking rule which is interest rate is 0
        ts::next_tx(&mut scenario, @treasury);
        {
            let mut testing_staking_config: StakingConfig = scenario.take_shared();
            let clock = clock::create_for_testing(scenario.ctx());
            let cap: AdminCap = scenario.take_from_sender();
            
            cap.add_staking_rule(&mut testing_staking_config, 
                                    STRANGE_STAKING_PERIOD, 
                                    STRANGE_INTEREST, 
                                    STRANGE_STAKING_QUANTITY_MIN, 
                                    STRANGE_STAKING_QUANTITY_MAX,
                                    &clock
                                    );
            ts::return_shared(testing_staking_config);
            scenario.return_to_sender(cap);
            clock::destroy_for_testing(clock);
        };
        // check that strange staking rule is added
        ts::next_tx(&mut scenario, @treasury);
        {
            let testing_config: StakingConfig = scenario.take_shared();
            let expected_strange_reward = testing_config.staking_reward(STRANGE_STAKING_PERIOD, 
                                                                CHAD_STAKED_AMOUNT);
            assert_eq(expected_strange_reward, ESTIMTED_REWARD_FROM_STRANGES);
            ts::return_shared(testing_config);
        };
        // generate staking receipt
        ts::next_tx(&mut scenario, @chad);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                CHAD_BALANCE,
                CHAD_STAKED_AMOUNT,
                STRANGE_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );
            transfer::public_transfer(receipt_obj, @chad);
            return_and_destory_test_objects(pool, config, clock);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EAmountTooHigh)]
    fun test_error_amount_toohigh_e4c_token_request() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @alice,
            MINTING_SMALL,
            ALICE_BALANCE,
            ALICE_STAKED_AMOUNT,
            ALICE_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        scenario.end();
    }

    #[test]
    fun test_staking_and_unstaking() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        ts::next_tx(&mut scenario, @bob);
        {  
            // ===== Start staking BOB ADDRESS=====
            let receipt_obj = staking_processes(
                BOB_BALANCE,
                BOB_STAKED_AMOUNT,
                BOB_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );

            assert_eq (receipt_obj.staking_receipt_amount(), BOB_STAKED_AMOUNT);
            assert_eq (receipt_obj.staking_receipt_staked_at(), CLOCK_SET_TIMESTAMP);
            assert_eq (receipt_obj.staking_receipt_applied_staking_days(), BOB_STAKING_PERIOD);
            assert_eq (receipt_obj.staking_receipt_applied_interest_rate_bp(), ESTIMATED_INTEREST_RATE_ON_60_DAYS);
            assert_eq (receipt_obj.staking_receipt_staking_end_at(), CLOCK_SET_TIMESTAMP + MILLIS_IN_60_DAYS);
            assert_eq (receipt_obj.staking_receipt_reward(), ESTIMATED_REWARD_TO_BOB);

            transfer::public_transfer(receipt_obj, @bob);   
        };
        // ===== Start unstaking BOB ADDRESS=====
        ts::next_tx(&mut scenario, @bob);
        {
            let mut clock = clock::create_for_testing(scenario.ctx());
            clock.set_for_testing(CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();
            // ===== Start unstaking =====
            clock.increment_for_testing(MILLIS_IN_60_DAYS);
            let reward_coin = received_staking_receipt.unstake(&clock, scenario.ctx());
            assert_eq(BOB_STAKED_AMOUNT + ESTIMATED_REWARD_TO_BOB, reward_coin.value());

            transfer::public_transfer(reward_coin, @bob);
            clock::destroy_for_testing(clock); 
        };
        scenario.end();
        
    }

    #[test]
    #[expected_failure(abort_code = EStakingQuantityTooHigh)]
    fun test_error_new_staking_receipt_over_max() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @bob,
            MINTING_AMOUNT,
            BOB_BALANCE_FOR_ERROR_TESTING,
            TOO_LARGE_STAKING_AMOUNT,
            BOB_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EStakingQuantityTooLow)]
    fun test_error_new_staking_receipt_less_min() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @bob,
            MINTING_AMOUNT,
            BOB_BALANCE,
            TOO_SMALL_STAKING_AMOUNT,
            BOB_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        scenario.end();
        
    }

    #[test]
    #[expected_failure(abort_code = EAmountMustBeGreaterThanZero)]    
    fun test_error_place_in_pool_zero_amount() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                0,
            )
        };
        scenario.end();
    }

    #[test]
    fun get_balance_in_game_liquidity_pool() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        ts::next_tx(&mut scenario, @treasury);
        {   
            let pool: GameLiquidityPool = scenario.take_shared();
            assert_eq(EXPECTED_GAME_LIQUIDITY_POOL_BALANCE, pool.game_liquidity_pool_balance());
            ts::return_shared(pool);
        };
        scenario.end();
        
    }

    #[test]
    fun get_staking_total_reward() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @bob,
            MINTING_AMOUNT,
            BOB_BALANCE,
            BOB_STAKED_AMOUNT,
            BOB_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @bob);
        {
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();
            assert_eq(received_staking_receipt.staking_receipt_total_reward_amount(), BOB_STAKED_AMOUNT + ESTIMATED_REWARD_TO_BOB);
            scenario.return_to_sender(received_staking_receipt);
        };
        
        scenario.end();
    }

    #[test]
    fun get_remained_staking_period() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @bob,
            MINTING_AMOUNT,
            BOB_BALANCE,
            BOB_STAKED_AMOUNT,
            BOB_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @bob);
        {
            let mut clock = clock::create_for_testing(scenario.ctx());
            clock.set_for_testing(CLOCK_SET_TIMESTAMP * 2);
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();
            let remained_staking_period = received_staking_receipt.staking_receipt_staking_remain_period(&clock);
            assert_eq(remained_staking_period, EXPECTED_REMAINING_PERIOD);
            ts::return_to_sender(&scenario, received_staking_receipt);
            clock.destroy_for_testing(); 
        };
        scenario.end();
    }

    #[test]
    fun get_remained_staking_period_finished_already() {
        let mut scenario = scenario();
        init_and_gen_staking_receipt(
            @bob,
            MINTING_AMOUNT,
            BOB_BALANCE,
            BOB_STAKED_AMOUNT,
            BOB_STAKING_PERIOD,
            CLOCK_SET_TIMESTAMP,
            &mut scenario
        );
        ts::next_tx(&mut scenario, @bob);
        {
            let mut clock = clock::create_for_testing(scenario.ctx());
            clock::set_for_testing(&mut clock, MILLIS_IN_90_DAYS + CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = scenario.take_from_sender<StakingReceipt>();
            let remained_staking_period = received_staking_receipt.staking_receipt_staking_remain_period(&clock);
            assert_eq(remained_staking_period, 0);
            scenario.return_to_sender(received_staking_receipt);
            clock::destroy_for_testing(clock); 
        };
        scenario.end();
    }


    #[test_only]
    fun set_up_initial_condition_for_testing(
        scenario: &mut Scenario,
        init_address: address,
        coin_amount: u64,
    ) {
        ts::next_tx(scenario, init_address);
        {
            staking::init_for_testing(ts::ctx(scenario));
        };
        ts::next_tx(scenario, init_address);
        {
            let mut pool: GameLiquidityPool = scenario.take_shared();
            let config: StakingConfig = scenario.take_shared();
            
            let total_minted_e4c = coin::mint_for_testing<E4C>(coin_amount, scenario.ctx()); 
            let total_minted_value = total_minted_e4c.value<E4C>();
            let mut total_balance = coin::into_balance<E4C>(total_minted_e4c);
            let e4c_to_pool = coin::take(&mut total_balance, total_minted_value/10, scenario.ctx());
            pool.place_in_pool(e4c_to_pool, scenario.ctx());
            
            ts::return_shared(pool);
            ts::return_shared(config);
            balance::destroy_for_testing(total_balance);
            
        }
        
    }

    fun staking_processes(
        current_balance: u64,
        staking_amount: u64,
        staking_period: u64,
        time_setting: u64,
        scenario: &mut Scenario,
    ): StakingReceipt {
        let (receipt_obj, pool, config, clock) = generate_staking_receipt_and_objects(
                current_balance,
                staking_amount,
                staking_period,
                time_setting,
                scenario
            );

        return_and_destory_test_objects(pool, config, clock);
        receipt_obj
    }

    fun scenario(): Scenario { ts::begin(@0x1) }    
}
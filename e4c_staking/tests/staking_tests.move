#[test_only]
module e4c_staking::staking_tests {
    use sui::balance::{Self};
    use sui::coin::{Self};
    use sui::clock::{Self, Clock};
    use sui::test_utils::{assert_eq};
    use sui::test_scenario as ts;
    use sui::test_scenario::{Scenario};

    use e4c_staking::staking::{Self, GameLiquidityPool, StakingReceipt, 
                        EStakingTimeNotEnded, EAmountMustBeGreaterThanZero, EAmountTooHigh};
    use e4c_staking::config::{AdminCap, StakingConfig, Self};
    use e4c::e4c::E4C;
    
    const CLOCK_SET_TIMESTAMP: u64 = 2024;
    const MILLIS_IN_90_DAYS: u64 = 7776000000;
    const MILLIS_IN_60_DAYS: u64 = 5184000000;

    const ALICE_BALANCE: u64 = 3_000;
    const ALICE_STAKED_AMOUNT : u64 = 2_000;
    const ALICE_STAKING_PERIOD: u64 = 90;

    const BOB_BALANCE: u64 = 300;
    const BOB_STAKED_AMOUNT : u64 = 100;
    const BOB_STAKING_PERIOD: u64 = 60;
    const ESTIMATED_REWARD_TO_BOB : u64 = 3;
    const ESTIMATED_INTEREST_RATE_ON_60_DAYS: u16 = 2000;

    const STRANGE_STAKING_PERIOD: u64 = 10_000;
    const STRANGE_INTEREST: u16 = 0;
    const STRANGE_STAKING_QUANTITY_MIN: u64 = 10_000;
    const STRANGE_STAKING_QUANTITY_MAX: u64 = 100_000;
    const ESTIMTED_REWARD_FROM_STRANGES : u64 = 0;
    const CHAD_BALANCE: u64 = 16_000;
    const CHAD_STAKED_AMOUNT : u64 = 12_000;

    const MINTING_AMOUNT: u64 = 100_000_000;
    const MINTING_SMALL : u64 = 10;

    #[test]
    public fun test_calculation_locking_time() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        ts::next_tx(&mut scenario, @alice);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                ALICE_BALANCE,
                ALICE_STAKED_AMOUNT,
                ALICE_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );
            return_and_destory_test_objects(pool, config, clock);
            let expected_stake_end_time = CLOCK_SET_TIMESTAMP + MILLIS_IN_90_DAYS;
            let stake_end_time = staking::staking_receipt_staking_end_at(&receipt_obj);
            assert_eq(stake_end_time, expected_stake_end_time);
            transfer::public_transfer(receipt_obj, @alice);
            
        };

        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EStakingTimeNotEnded)]
    public fun test_error_calculation_locking_time() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        
        ts::next_tx(&mut scenario, @alice);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                ALICE_BALANCE,
                ALICE_STAKED_AMOUNT,
                ALICE_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );
            return_and_destory_test_objects(pool, config, clock);
            transfer::public_transfer(receipt_obj, @alice);
            
        };
        ts::next_tx(&mut scenario, @alice);
        {
            let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::set_for_testing(&mut clock, CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = ts::take_from_sender<StakingReceipt>(&scenario);

            clock::increment_for_testing(&mut clock, MILLIS_IN_60_DAYS); // 5184000000 for 60 days 
            let reward_coin = staking::unstake(received_staking_receipt, &clock, ts::ctx(&mut scenario));
            transfer::public_transfer(reward_coin, @alice);
            clock::destroy_for_testing(clock); 

        };

        ts::end(scenario);
    }

    #[test]
    public fun test_e4c_token_request() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_AMOUNT,
            )
        };
        
        ts::next_tx(&mut scenario, @alice);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                ALICE_BALANCE,
                ALICE_STAKED_AMOUNT,
                ALICE_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );
            let get_expected_reward = config::staking_reward(&config, ALICE_STAKING_PERIOD, ALICE_STAKED_AMOUNT);
            let requested_amount_from_pool = staking::staking_receipt_reward(&receipt_obj);
            assert_eq(get_expected_reward, requested_amount_from_pool);
            transfer::public_transfer(receipt_obj, @alice);
            return_and_destory_test_objects(pool, config, clock);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EAmountMustBeGreaterThanZero)]
    public fun test_error_amount_zero_e4c_token_request() {
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
            let mut testing_staking_config: StakingConfig = ts::take_shared(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let cap: AdminCap = ts::take_from_sender(&scenario);
            
            config::add_staking_rule(&cap, 
                                    &mut testing_staking_config, 
                                    STRANGE_STAKING_PERIOD, 
                                    STRANGE_INTEREST, 
                                    STRANGE_STAKING_QUANTITY_MIN, 
                                    STRANGE_STAKING_QUANTITY_MAX,
                                    &clock
                                    );
            ts::return_shared(testing_staking_config);
            ts::return_to_sender(&scenario,cap);
            clock::destroy_for_testing(clock);
        };
        // check that strange staking rule is added
        ts::next_tx(&mut scenario, @treasury);
        {
            let testing_config: StakingConfig = ts::take_shared(&scenario);

            let expected_strange_reward = config::staking_reward(&testing_config, 
                                                                STRANGE_STAKING_PERIOD, 
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
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EAmountTooHigh)]
    public fun test_error_amount_toohigh_e4c_token_request() {
        let mut scenario = scenario();
        ts::next_tx(&mut scenario, @treasury);
        {
            set_up_initial_condition_for_testing(
                &mut scenario,
                @treasury,
                MINTING_SMALL,
            )
        };
        ts::next_tx(&mut scenario, @bob);
        {
            let (receipt_obj, pool, config, clock)  = generate_staking_receipt_and_objects(
                BOB_BALANCE,
                BOB_STAKED_AMOUNT,
                BOB_STAKING_PERIOD,
                CLOCK_SET_TIMESTAMP,
                &mut scenario
            );
            transfer::public_transfer(receipt_obj, @bob);
            return_and_destory_test_objects(pool, config, clock);
        };
        ts::end(scenario);
    }

    #[test]
    public fun test_staking_and_unstaking() {
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
            
            
            let stake_amount = staking::staking_receipt_amount(&receipt_obj);
            let stake_start_time = staking::staking_receipt_staked_at(&receipt_obj);
            let staking_period = staking::staking_receipt_applied_staking_days(&receipt_obj);
            let interest_rate = staking::staking_receipt_applied_interest_rate_bp(&receipt_obj);
            let staking_finish_time = staking::staking_receipt_staking_end_at(&receipt_obj);
            let reward_amount = staking::staking_receipt_reward(&receipt_obj);
            assert_eq (stake_amount, BOB_STAKED_AMOUNT);
            assert_eq (stake_start_time, CLOCK_SET_TIMESTAMP);
            assert_eq (staking_period, BOB_STAKING_PERIOD);
            assert_eq (interest_rate, ESTIMATED_INTEREST_RATE_ON_60_DAYS);
            assert_eq (staking_finish_time, CLOCK_SET_TIMESTAMP + MILLIS_IN_60_DAYS);
            assert_eq (reward_amount, ESTIMATED_REWARD_TO_BOB);

            transfer::public_transfer(receipt_obj, @bob);   
        };
        // ===== Start unstaking BOB ADDRESS=====
        ts::next_tx(&mut scenario, @bob);
        {
            let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::set_for_testing(&mut clock, CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = ts::take_from_sender<StakingReceipt>(&scenario);
            // ===== Start unstaking =====
            clock::increment_for_testing(&mut clock, MILLIS_IN_60_DAYS);
            let reward_coin = staking::unstake(received_staking_receipt, &clock, ts::ctx(&mut scenario));
            
            let expected_total_return_amount : u64 = BOB_STAKED_AMOUNT + ESTIMATED_REWARD_TO_BOB;
            let reward_value = coin::value(&reward_coin);
            assert_eq(expected_total_return_amount, reward_value);

            transfer::public_transfer(reward_coin, @bob);
            clock::destroy_for_testing(clock); 
        };
        ts::end(scenario);
        
    }
    #[test_only]
    public fun set_up_initial_condition_for_testing(
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
            let mut pool: GameLiquidityPool = ts::take_shared(scenario);
            let config: StakingConfig = ts::take_shared(scenario);
            
            let total_minted_e4c = coin::mint_for_testing<E4C>(coin_amount, ts::ctx(scenario)); 
            let total_minted_value = coin::value<E4C>(&total_minted_e4c);
            let mut total_balance = coin::into_balance<E4C>(total_minted_e4c);
            let e4c_to_pool = coin::take(&mut total_balance, total_minted_value/10, ts::ctx(scenario));
            staking::place_in_pool(&mut pool, e4c_to_pool, ts::ctx(scenario));
            
            ts::return_shared(pool);
            ts::return_shared(config);
            balance::destroy_for_testing(total_balance);
            
        }
        
    }

    #[test_only]
    public fun staking_processes(
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
        staking_period: u64,
        time_setting: u64,
        scenario: &mut Scenario,
    ): (StakingReceipt, GameLiquidityPool, StakingConfig, Clock) {
        let mut balance = balance::create_for_testing(current_balance);
        let stake = coin::take(&mut balance, staking_amount, ts::ctx(scenario));    
        let mut clock = clock::create_for_testing(ts::ctx(scenario));
        clock::set_for_testing(&mut clock, time_setting);
        let mut pool: GameLiquidityPool = ts::take_shared(scenario);
        let config: StakingConfig = ts::take_shared(scenario);
        
        let receipt_obj = staking::new_staking_receipt(
            stake, 
            staking_period,
            &clock,
            &config,
            &mut pool, 
            ts::ctx(scenario)
        );
        balance::destroy_for_testing(balance);
        (receipt_obj, pool, config, clock)
    }

    fun scenario(): Scenario { ts::begin(@0x1) }    
}
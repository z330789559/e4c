#[test_only]
module e4c_staking::staking_tests {
    use sui::balance::{Self};
    use sui::coin::{Self};
    use sui::clock::{Self};
    use sui::test_utils::{assert_eq};
    use sui::test_scenario as ts;
    use sui::test_scenario::{Scenario};

    use e4c_staking::staking::{Self, GameLiquidityPool, StakingReceipt};
    use e4c_staking::config::{StakingConfig};
    use e4c::e4c::E4C;
    
    const CLOCK_SET_TIMESTAMP: u64 = 2024;

    const BOB_BALANCE: u64 = 300;
    const BOB_STAKED_AMOUNT : u64 = 100;
    const BOB_STAKING_PERIOD: u64 = 60;

    const MINTING_AMOUNT: u64 = 100_000_000;
    
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
            let mut pool: GameLiquidityPool = ts::take_shared(&scenario);
            let config: StakingConfig = ts::take_shared(&scenario);
            let mut bob_balance = balance::create_for_testing(BOB_BALANCE);
            let bob_stake = coin::take(&mut bob_balance, BOB_STAKED_AMOUNT, ts::ctx(&mut scenario));
            let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::set_for_testing(&mut clock, CLOCK_SET_TIMESTAMP);
            let receipt_obj = staking::new_staking_receipt(
                bob_stake, 
                BOB_STAKING_PERIOD,
                &clock,
                &config,
                &mut pool, 
                ts::ctx(&mut scenario)
            );
            
            let (stake_amount, 
                stake_start_time, 
                staking_period, 
                interest_rate, 
                staking_finish_time,
                reward_amount
                ) = staking::staking_receipt_data(&receipt_obj);
            assert_eq (stake_amount, BOB_STAKED_AMOUNT);
            assert_eq (stake_start_time, CLOCK_SET_TIMESTAMP);
            assert_eq (staking_period, BOB_STAKING_PERIOD);
            assert_eq (interest_rate, 2000);
            assert_eq (staking_finish_time, CLOCK_SET_TIMESTAMP + 5184000000);
            assert_eq (reward_amount, 33);
            staking::transfer_staking_receipt(receipt_obj, @bob);
           
            balance::destroy_for_testing(bob_balance);
            clock::destroy_for_testing(clock); 
            ts::return_shared(pool);
            ts::return_shared(config);
             
         };
         // ===== Start unstaking BOB ADDRESS=====
         ts::next_tx(&mut scenario, @bob);
         {

            let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::set_for_testing(&mut clock, CLOCK_SET_TIMESTAMP);
            let received_staking_receipt = ts::take_from_sender<StakingReceipt>(&scenario);
            // ===== Start unstaking =====
            clock::increment_for_testing(&mut clock, 5184000000);
            let reward_coin = staking::unstake(received_staking_receipt, &clock, ts::ctx(&mut scenario));
            
            let expected_total_return_amount : u64 = 100 + 33;
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

    fun scenario(): Scenario { ts::begin(@0x1) }    
}
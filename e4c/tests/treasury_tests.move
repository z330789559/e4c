#[test_only]
module e4c::treasury_tests {
    use std::debug;
    use e4c::e4c::{Self, E4C};
    use sui::coin::{Self, Coin, TreasuryCap, DenyCap};
    use e4c::treasury::{Self, TreasuryCapKey, ControlledTreasury, ControlledTreasuryCap};
    use sui::test_utils::assert_eq;
    use sui::test_scenario as ts;
    use sui::test_scenario::{Scenario, Self};

    const E4C_MINTING_AMOUNT: u64 = 10_000_000;
    const E4C_MINTING_AMOUNT_LIMIT: u64 = 100_000_000;

    #[test]
    fun test_check_controlled_treasury_cap() {
        let mut scenario = ts::begin(@ambrus);
        let mut expected_controlled_treasury_cap_id: vector<u8> = vector::empty();
        
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury = scenario.take_from_sender<TreasuryCap<E4C>>();
            let deny_cap = scenario.take_from_sender<DenyCap<E4C>>();
            assert_eq(treasury.total_supply(), 0);

            scenario.return_to_sender(treasury);
            scenario.return_to_sender(deny_cap);
        };

        // Start to mint controlled_treasury_cap
        // Expected E4C Minting amount is 100_000_000
        // Meant that ControlledTreasury mint limit is 100_000_000
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury_cap = scenario.take_from_sender<TreasuryCap<E4C>>();
            let controlled_treasury_cap = treasury::new(treasury_cap, E4C_MINTING_AMOUNT_LIMIT, ts::ctx(&mut scenario));
            expected_controlled_treasury_cap_id = object::id_bytes(&controlled_treasury_cap);
            
            transfer::public_transfer(controlled_treasury_cap, @ambrus);
            
        };
        
        //Check ambrus account has controlled_treasury_cap
        ts::next_tx(&mut scenario, @ambrus);
        {
            let controlled_treasury_cap = scenario.take_from_sender<ControlledTreasuryCap>();
            let controlled_treasury_cap_id_to_bytes = object::id_bytes(&controlled_treasury_cap);
            assert_eq(controlled_treasury_cap_id_to_bytes, expected_controlled_treasury_cap_id);
            scenario.return_to_sender(controlled_treasury_cap);
        };

        ts::end(scenario);
    }


    #[test]
    fun test_mint_e4c_in_allowed_range () {
        let mut scenario = ts::begin(@ambrus);
        let mut expected_controlled_treasury_cap_id: vector<u8> = vector::empty();
        
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury = scenario.take_from_sender<TreasuryCap<E4C>>();
            let deny_cap = scenario.take_from_sender<DenyCap<E4C>>();
            assert_eq(treasury.total_supply(), 0);

            scenario.return_to_sender(treasury);
            scenario.return_to_sender(deny_cap);
        };

        // Start to mint controlled_treasury_cap
        // Expected E4C Minting amount is 100_000_000
        // Meant that ControlledTreasury mint limit is 100_000_000
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury_cap = scenario.take_from_sender<TreasuryCap<E4C>>();
            let controlled_treasury_cap = treasury::new(treasury_cap, E4C_MINTING_AMOUNT, ts::ctx(&mut scenario));
            transfer::public_transfer(controlled_treasury_cap, @ambrus);
            
            
            
        };
        // Mint E4C
        ts::next_tx(&mut scenario, @ambrus);
        {
            let controlled_treasury_cap = scenario.take_from_sender<ControlledTreasuryCap>();
            let mut controlled_tresury = ts::take_shared(&scenario);
            let minted_e4c = treasury::mint<E4C>(&mut controlled_tresury, &controlled_treasury_cap, E4C_MINTING_AMOUNT, ts::ctx(&mut scenario));
            let minted_e4c_balance_amount = coin::value(&minted_e4c);
            assert_eq(minted_e4c_balance_amount, E4C_MINTING_AMOUNT);
            transfer::public_transfer(minted_e4c, @ambrus);
            scenario.return_to_sender(controlled_treasury_cap);
            ts::return_shared(controlled_tresury);
        };
        ts::end(scenario);
    }

    // #[test]
    // #[expected_failure]
    // fun test_error_mint_e4c_out_of_allowed_range () {

    // }

    // #[test]
    // fun test_burn_e4c () {

    // }

    // #[test]
    // #[expected_failure]
    // fun test_error_burn_e4c_more_than_minted_amount () {

    // }

}
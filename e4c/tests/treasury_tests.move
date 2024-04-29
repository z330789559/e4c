#[test_only]
module e4c::treasury_tests {
    use e4c::e4c::{Self, E4C};
    use sui::coin::{Self, TreasuryCap, DenyCap};
    use e4c::treasury::{Self, ControlledTreasuryCap, ControlledTreasury, EExceedMintingLimit};
    use sui::test_utils::assert_eq;
    use sui::test_scenario as ts;
    use sui::test_scenario::{Scenario};

    const E4C_MINTING_AMOUNT: u64 = 10_000_000;
    const E4C_EXCEEDED_MINTING_AMOUNT: u64 = 1_000_000_000;
    const E4C_MINTING_AMOUNT_LIMIT: u64 = 100_000_000;

    #[test]
    fun test_check_controlled_treasury_cap() {
        let mut scenario = ts::begin(@ambrus);
        let mut _expected_controlled_treasury_cap_id: vector<u8> = vector::empty();
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            init_for_treasury_tests(&mut scenario);
        };

        // Start to mint controlled_treasury_cap
        // Expected E4C Minting amount is 100_000_000
        // Meant that ControlledTreasury mint limit is 100_000_000
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury_cap = scenario.take_from_sender<TreasuryCap<E4C>>();
            let controlled_treasury_cap = treasury::new(treasury_cap, E4C_MINTING_AMOUNT_LIMIT, ts::ctx(&mut scenario));
            _expected_controlled_treasury_cap_id = object::id_bytes(&controlled_treasury_cap);
            transfer::public_transfer(controlled_treasury_cap, @ambrus);
        };
        
        //Check ambrus account has controlled_treasury_cap
        ts::next_tx(&mut scenario, @ambrus);
        {
            let controlled_treasury_cap = scenario.take_from_sender<ControlledTreasuryCap>();
            let controlled_treasury_cap_id_to_bytes = object::id_bytes(&controlled_treasury_cap);
            assert_eq(controlled_treasury_cap_id_to_bytes, _expected_controlled_treasury_cap_id);
            scenario.return_to_sender(controlled_treasury_cap);
        };

        ts::end(scenario);
    }


    #[test]
    fun test_mint_e4c_in_allowed_range () {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            init_for_treasury_tests(&mut scenario);
        };

        // Start to mint controlled_treasury_cap
        // Expected E4C Minting amount is 100_000_000
        // Meant that ControlledTreasury mint limit is 100_000_000
        ts::next_tx(&mut scenario, @ambrus);
        {
            mint_cap(&mut scenario, E4C_MINTING_AMOUNT_LIMIT);
        };
        // Mint E4C
        ts::next_tx(&mut scenario, @ambrus);
        {
            let minted_e4c_balance_amount = mint_e4c(&mut scenario, E4C_MINTING_AMOUNT);
            assert_eq(minted_e4c_balance_amount, E4C_MINTING_AMOUNT);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = EExceedMintingLimit)]
    fun test_error_mint_e4c_out_of_allowed_range () {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            init_for_treasury_tests(&mut scenario);
        };

        // Start to mint controlled_treasury_cap
        // Expected E4C Minting amount is 100_000_000
        // Meant that ControlledTreasury mint limit is 100_000_000
        ts::next_tx(&mut scenario, @ambrus);
        {
            mint_cap(&mut scenario, E4C_MINTING_AMOUNT_LIMIT);
        };
        // Mint E4C
        ts::next_tx(&mut scenario, @ambrus);
        {
            let minted_e4c_balance_amount = mint_e4c(&mut scenario, E4C_EXCEEDED_MINTING_AMOUNT);
            assert_eq(minted_e4c_balance_amount, E4C_EXCEEDED_MINTING_AMOUNT);
        };
        ts::end(scenario);
    }

    fun init_for_treasury_tests(_scenario: &mut Scenario) {
        let treasury = _scenario.take_from_sender<TreasuryCap<E4C>>();
        let deny_cap = _scenario.take_from_sender<DenyCap<E4C>>();
        _scenario.return_to_sender(treasury);
        _scenario.return_to_sender(deny_cap);        
    }


    fun get_cap_and_treasury(scenario: &Scenario): (ControlledTreasuryCap, ControlledTreasury<E4C>){
        let controlled_treasury_cap = scenario.take_from_sender<ControlledTreasuryCap>();
        let controlled_tresury = ts::take_shared(scenario);
        (controlled_treasury_cap, controlled_tresury)
    }

    fun mint_cap(
        scenario: &mut Scenario,
        minting_limit: u64){
        let treasury_cap = scenario.take_from_sender<TreasuryCap<E4C>>();
        let controlled_treasury_cap = treasury::new(treasury_cap, minting_limit, ts::ctx(scenario));
        transfer::public_transfer(controlled_treasury_cap, @ambrus);
    }

    fun mint_e4c(
        scenario: &mut Scenario,
        minting_amount : u64
    ): u64{
        let (controlled_treasury_cap , mut controlled_tresury) = get_cap_and_treasury(scenario);
        let minted_e4c = treasury::mint<E4C>(&mut controlled_tresury, &controlled_treasury_cap, minting_amount, ts::ctx(scenario));
        let minted_e4c_balance_amount = coin::value(&minted_e4c);
        transfer::public_transfer(minted_e4c, @ambrus);
        scenario.return_to_sender(controlled_treasury_cap);
        ts::return_shared(controlled_tresury);
        minted_e4c_balance_amount
    }
}
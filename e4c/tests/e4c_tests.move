#[test_only]
module e4c::e4c_tests {
    use e4c::e4c::{Self, E4C, E4CTotalSupply};
    use sui::{
        test_utils::assert_eq, 
        test_scenario as ts,
        coin::{TreasuryCap, DenyCap}
    };

    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000;
    #[test]
    #[expected_failure]
    fun test_treasury_cap_is_burnt() {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury = scenario.take_from_sender<TreasuryCap<E4C>>();
            scenario.return_to_sender(treasury);
        };
        scenario.end();
    }
    #[test]
    fun test_deny_cap_existed() {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(scenario.ctx());
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let deny = scenario.take_from_sender<DenyCap<E4C>>();
            scenario.return_to_sender(deny);
        };
        scenario.end();
    }

    #[test]
    fun test_immutable_supply() {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            assert!(!scenario.has_most_recent_for_sender<E4CTotalSupply>(), 0);
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let supply_data = scenario.take_immutable<E4CTotalSupply>();
            let total_supply = supply_data.get_total_supply();
            assert_eq(total_supply, EXPECTED_TOTAL_SUPPLY);
            ts::return_immutable(supply_data);
        };
        scenario.end();
    }

}

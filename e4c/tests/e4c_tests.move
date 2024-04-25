#[test_only]
module e4c::e4c_tests {
    use e4c::e4c::{Self, E4C};
    use sui::test_utils::assert_eq;
    use sui::test_scenario as ts;
    use sui::coin::{TreasuryCap, DenyCap};


    #[test]
    fun test_coin_publishing() {
        let mut scenario = ts::begin(@ambrus);
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
        scenario.end();
    }
}

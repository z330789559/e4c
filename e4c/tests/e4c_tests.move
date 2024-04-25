#[test_only]
module e4c::e4c_tests {
    use e4c::e4c::{Self, E4C};
    use sui::test_utils::assert_eq;
    use sui::test_scenario as ts;
    use sui::coin::TreasuryCap;
    
    
    #[test]
    fun test_coin_publishing() {
        let mut scenario = ts::begin(@ambrus);
        {
            e4c::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, @ambrus);
        {
            let treasury_cap = ts::take_from_sender<TreasuryCap<E4C>>(&scenario);
            assert_eq(treasury_cap.total_supply(), 0);
            ts::return_to_sender(&scenario, treasury_cap);
        };
        ts::end(scenario);

    }
}

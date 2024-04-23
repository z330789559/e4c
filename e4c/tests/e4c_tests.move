#[test_only]
module e4c::e4c_tests {
    use e4c::e4c::{Self, E4CTotalSupply};
    use sui::test_utils::assert_eq;
    use sui::test_scenario as ts;
    
    const AMBRUS_ADDRESS: address = @0xAAAA;
    const EXPECTED_TOTAL_SUPPLY: u64 = 1_000_000_000;

    #[test]
    // Ref: https://docs.sui.io/concepts/object-ownership/immutable#test-immutable-object
    fun test_object_is_freezing() {
        let mut scenario = ts::begin(AMBRUS_ADDRESS);
        {
            e4c::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, AMBRUS_ADDRESS);
        {
            assert!(!ts::has_most_recent_for_sender<E4CTotalSupply>(&scenario), 0);
        };
        ts::next_tx(&mut scenario, AMBRUS_ADDRESS);
        {
            let meta_data_obj = ts::take_immutable<E4CTotalSupply>(&scenario);
            let total_supply = e4c::get_total_supply(&meta_data_obj);
            assert_eq(total_supply, EXPECTED_TOTAL_SUPPLY);
            ts::return_immutable(meta_data_obj);

        };
        ts::end(scenario);

    }
}

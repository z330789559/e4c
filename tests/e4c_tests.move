#[test_only]
module e4c::e4c_tests {
    // uncomment this line to import the module
    // use e4c::e4c;
    
    const ENotImplemented: u64 = 0;
    
    #[test]
    fun test_e4c() {
        // pass
    }
    
    #[test, expected_failure(abort_code = e4c::e4c_tests::ENotImplemented)]
    fun test_e4c_fail() {
        abort ENotImplemented
    }
}

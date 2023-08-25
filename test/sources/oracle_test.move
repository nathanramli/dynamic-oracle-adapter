#[test_only]
module oracle_test::oracle_test {
    use oracle::price_feeds::{Self, PriceFeedsCap, PriceFeeds};
    use oracle::update_requests;
    use adapter::oracle_adapter::{Self, Rule};
    use sui::test_scenario;
    use sui::clock;

    #[test_only]
    struct BTC has drop {}

    #[test]
    fun oracle_test() {
        let admin = @0xAA;
        let user = @0xBB;

        let scenario_value = test_scenario::begin(admin);
        let scenario = &mut scenario_value;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        {
            price_feeds::init_test(test_scenario::ctx(scenario));
            test_scenario::next_tx(scenario, user);
        };
        let price_feeds = test_scenario::take_shared<PriceFeeds>(scenario);
        let price_feeds_cap = test_scenario::take_from_address<PriceFeedsCap>(scenario, admin);
        
        test_scenario::next_tx(scenario, admin);
        {
            price_feeds::update_rule<BTC, Rule>(
                &price_feeds_cap,
                &mut price_feeds,
            );            
        };

        test_scenario::next_tx(scenario, user);
        let update_request = update_requests::new_update_request<BTC>();
        oracle_adapter::update_price<BTC>(
            &mut update_request,
            100,
        );
        update_requests::confirm_request<BTC>(
            update_request,
            &mut price_feeds,
            &clock,
        );
        
        // make sure the price is updated
        assert!(price_feeds::get_price<BTC>(&price_feeds, &clock) == 100, 1);

        clock::destroy_for_testing(clock);
        test_scenario::return_to_address(admin, price_feeds_cap);
        test_scenario::return_shared(price_feeds);
        test_scenario::end(scenario_value);
    }
}
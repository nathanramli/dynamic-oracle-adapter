module oracle::update_requests {
    use std::option::{Self, Option};
    use std::type_name::{Self, TypeName};
    use sui::clock::Clock;
    use oracle::price_feeds::{Self, PriceFeeds};

    struct UpdateRequest<phantom CoinType> {
        rule: Option<TypeName>,
        price: u64,
    }

    const InvalidRuleErr: u64 = 1;

    public fun new_update_request<CoinType>(): UpdateRequest<CoinType> {
        UpdateRequest<CoinType> {
            rule: option::none(),
            price: 0,
        }
    }

    public fun update<CoinType, Rule: drop>(
        update_request: &mut UpdateRequest<CoinType>,
        _: Rule,
        price: u64,
    ) {
        update_request.rule = option::some(type_name::get<Rule>());
        update_request.price = price;
    }

    public fun confirm_request<CoinType>(
        update_request: UpdateRequest<CoinType>,
        price_feeds: &mut PriceFeeds,
        clock: &Clock,
    ) {
        let UpdateRequest { rule, price } = update_request;
        assert!(option::is_some(&rule), InvalidRuleErr);

        let rule = option::destroy_some(rule);
        assert!(&rule == price_feeds::policy<CoinType>(price_feeds), InvalidRuleErr);

        price_feeds::update_price<CoinType>(price_feeds, price, clock);
    }
}
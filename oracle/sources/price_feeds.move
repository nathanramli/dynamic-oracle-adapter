module oracle::price_feeds {
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::type_name::{Self, TypeName};

    friend oracle::update_requests;

    const PriceStaleErr: u64 = 1;

    struct PriceFeed has store {
        price: u64,
        last_updated: u64,
    }

    struct PriceFeedsCap has key, store {
        id: UID,
    }

    struct PriceFeeds has key {
        id: UID,
        policy: Table<TypeName, TypeName>,
        prices: Table<TypeName, PriceFeed>,
    }

    public fun policy<CoinType>(self: &PriceFeeds): &TypeName { table::borrow(&self.policy, type_name::get<CoinType>()) }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(PriceFeeds {
            id: object::new(ctx),
            policy: table::new(ctx),
            prices: table::new(ctx),
        });

        transfer::transfer(PriceFeedsCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(ctx)
    }

    public fun update_rule<CoinType, Rule: drop>(
        _: &PriceFeedsCap,
        price_feeds: &mut PriceFeeds,
    ) {
        let coin_type = type_name::get<CoinType>();
        let rule_type = type_name::get<Rule>();

        if (table::contains(&price_feeds.policy, coin_type)) {
            table::remove(&mut price_feeds.policy, coin_type);
        };

        table::add(&mut price_feeds.policy, coin_type, rule_type);
    }

    public(friend) fun update_price<CoinType>(
        price_feeds: &mut PriceFeeds,
        price: u64,
        clock: &Clock,
    ) {
        let coin_type = type_name::get<CoinType>();
        let now = clock::timestamp_ms(clock) / 1000;

        if (!table::contains(&price_feeds.prices, coin_type)) {
            table::add(&mut price_feeds.prices, coin_type, PriceFeed {
                price: price,
                last_updated: now,
            });
        } else {
            let price_feed = table::borrow_mut(&mut price_feeds.prices, coin_type);

            price_feed.price = price;
            price_feed.last_updated = now;
        };
    }

    public fun get_price<CoinType>(
        price_feeds: &PriceFeeds,
        clock: &Clock,
    ): u64 {
        let coin_type = type_name::get<CoinType>();
        let now = clock::timestamp_ms(clock) / 1000;

        let price_feed = table::borrow(&price_feeds.prices, coin_type);
        assert!(price_feed.last_updated == now, PriceStaleErr);

        price_feed.price
    }
}
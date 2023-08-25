module adapter::oracle_adapter {
    use oracle::update_requests::{Self, UpdateRequest};

    struct Rule has drop {}

    public fun update_price<CoinType>(
        update_request: &mut UpdateRequest<CoinType>,
        price: u64,
    ) {
        // do update your price here
        update_requests::update<CoinType, Rule>(
            update_request,
            Rule {},
            price,
        );
    }
}
module aptin_lend::price {
    use std::signer;
    use std::error;
    use aptos_std::type_info;


    // use aptin_lend::res;

    friend aptin_lend::lend;
    friend aptin_lend::pool;

    const EPRICE_ADDRESS_MISMATCH: u64 = 0;
    const EPRICE_ALREADY_PUBLISHED: u64 = 1;
    const EPRICE_NOT_BE_PUBLISHED: u64 = 2;

    struct Price<phantom CoinType> has key, store {
        value: u64
    }

    public(friend) fun initialize<CoinType>(account: &signer, value: u64) {
        assert!(!exists<Price<CoinType>>(signer::address_of(account)), error::invalid_state(EPRICE_ALREADY_PUBLISHED));

        move_to(account, Price<CoinType> {
            value
        });
    }

    public entry fun update<CoinType>(value: u64) acquires Price  {
        let type_info = type_info::type_of<CoinType>();
        let account_addr = type_info::account_address(&type_info);
        assert!(exists<Price<CoinType>>(account_addr), error::unavailable(EPRICE_NOT_BE_PUBLISHED));

        let old_value = &mut borrow_global_mut<Price<CoinType>>(account_addr).value;

        *old_value = value;
    }

    public(friend) fun get_price<CoinType>(account_addr: address): u64 acquires Price {
        exists<Price<CoinType>>(account_addr);

        let value = borrow_global<Price<CoinType>>(account_addr).value;
        *&value
    }
}
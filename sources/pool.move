module aptin_lend::pool {
    use std::signer;
    use std::error;

    use aptos_std::simple_map;

    use aptos_framework::aptos_coin::AptosCoin;

    use aptin_lend::coins::{BTC, USDT, ETH, USDC};
    use aptin_lend::price;

    friend aptin_lend::lend;

    const EALREADY_EXISTS_POOL: u64 = 1;
    const ENOT_EXISTS_POOL: u64 = 2;
    const EINSUFFICIENT_SUPPLY: u64 = 3;
    const EINSUFFICIENT_BORROW: u64 = 4;


    /// Record pool information
    struct SupplyPool<phantom CoinType> has store {
        user_supply: simple_map::SimpleMap<address, u64>,
        total_supply: u128,
    }

    struct BorrowPool<phantom CoinType> has store {
        user_borrow: simple_map::SimpleMap<address, u64>,
        total_borrow: u128,
    }

    struct AptinPool<phantom CoinType> has key {
        supply_pool: SupplyPool<CoinType>,
        borrow_pool: BorrowPool<CoinType>,
    }

    public(friend) fun init_pool<CoinType>(pool: &signer) {
        assert!(!exists<AptinPool<CoinType>>(signer::address_of(pool)), error::already_exists(EALREADY_EXISTS_POOL));

        move_to(pool,
            AptinPool<CoinType>{
                supply_pool: SupplyPool<CoinType> {
                    user_supply: simple_map::create(),
                    total_supply: 0
                },
                borrow_pool: BorrowPool<CoinType> {
                    user_borrow: simple_map::create(),
                    total_borrow: 0
                }
        });

    }

    public(friend) fun exists_pool<CoinType>(pool_addr: address): bool {
        exists<AptinPool<CoinType>>(pool_addr)
    }

    public(friend) fun increase_supply_pool<CoinType>(pool_addr: address, user_addr: address, amount: u64) acquires AptinPool {
        assert!(exists<AptinPool<CoinType>>(pool_addr), error::not_found(ENOT_EXISTS_POOL));

        let pool = borrow_global_mut<AptinPool<CoinType>>(pool_addr);

        // udpate user supply
        if (simple_map::contains_key<address, u64>(&pool.supply_pool.user_supply, &user_addr)) {
            let supply = simple_map::borrow_mut<address, u64>(&mut pool.supply_pool.user_supply, &user_addr);
            *supply = *supply + amount;
        } else {
            simple_map::add<address, u64>(&mut pool.supply_pool.user_supply, user_addr, amount);
        };

        // update total supply
        *&mut pool.supply_pool.total_supply = *&mut pool.supply_pool.total_supply + (amount as u128);
    }

    public(friend) fun increase_borrow_pool<CoinType>(pool_addr: address, user_addr: address, amount: u64) acquires AptinPool {
        // assert!(exists<AptinPool<CoinType>>(pool_addr), error::not_found(ENOT_EXISTS_POOL));

        let pool = borrow_global_mut<AptinPool<CoinType>>(pool_addr);

        // udpate user supply
        if (simple_map::contains_key<address, u64>(&pool.borrow_pool.user_borrow, &user_addr)) {
            let borrow = simple_map::borrow_mut<address, u64>(&mut pool.borrow_pool.user_borrow, &user_addr);
            *borrow = *borrow + amount;
        } else {
            simple_map::add<address, u64>(&mut pool.borrow_pool.user_borrow, user_addr, amount);
        };

        // update total supply
        *&mut pool.borrow_pool.total_borrow = *&mut pool.borrow_pool.total_borrow + (amount as u128);
    }

    public(friend) fun decrease_supply_pool<CoinType>(pool_addr: address, user_addr: address, amount: u64) acquires AptinPool {
        assert!(exists<AptinPool<CoinType>>(pool_addr), error::not_found(ENOT_EXISTS_POOL));

        let pool = borrow_global_mut<AptinPool<CoinType>>(pool_addr);

        // udpate user supply
        if (simple_map::contains_key<address, u64>(&pool.supply_pool.user_supply, &user_addr)) {
            let supply = simple_map::borrow_mut<address, u64>(&mut pool.supply_pool.user_supply, &user_addr);
            assert!(*supply >= amount, error::aborted(EINSUFFICIENT_SUPPLY));
            *supply = *supply - amount;
        };

        // update total supply
        *&mut pool.supply_pool.total_supply = *&mut pool.supply_pool.total_supply - (amount as u128);
    }

    public(friend) fun decrease_borrow_pool<CoinType>(pool_addr: address, user_addr: address, amount: u64) acquires AptinPool {
        assert!(exists<AptinPool<CoinType>>(pool_addr), error::not_found(ENOT_EXISTS_POOL));

        let pool = borrow_global_mut<AptinPool<CoinType>>(pool_addr);

        // udpate user supply
        if (simple_map::contains_key<address, u64>(&pool.borrow_pool.user_borrow, &user_addr)) {
            let borrow = simple_map::borrow_mut<address, u64>(&mut pool.borrow_pool.user_borrow, &user_addr);
            assert!(*borrow >= amount, error::aborted(EINSUFFICIENT_BORROW));
            *borrow = *borrow - amount;
        };

        // update total supply
        *&mut pool.borrow_pool.total_borrow = *&mut pool.borrow_pool.total_borrow - (amount as u128);
    }



    fun get_supply_by_user_cion<CoinType>(pool_addr: address, user_addr: address): u128 acquires AptinPool {
        if (exists_pool<CoinType>(pool_addr)) {
            let pool = borrow_global<AptinPool<CoinType>>(pool_addr);

            if (simple_map::contains_key<address, u64>(&pool.supply_pool.user_supply, &user_addr)) {
                let amount = simple_map::borrow<address, u64>(&pool.supply_pool.user_supply, &user_addr);
                let price = price::get_price<CoinType>(pool_addr);
                ((*amount * price) as u128)
            } else { 0 }
        } else { 0 }
    }


    fun get_borrow_by_user_coin<CoinType>(pool_addr: address, user_addr: address): u128 acquires AptinPool {
        if (exists_pool<CoinType>(pool_addr)) {
            let pool = borrow_global<AptinPool<CoinType>>(pool_addr);

            if (simple_map::contains_key<address, u64>(&pool.borrow_pool.user_borrow, &user_addr)) {
                let amount = simple_map::borrow<address, u64>(&pool.borrow_pool.user_borrow, &user_addr);
                let price = price::get_price<CoinType>(pool_addr);
                ((*amount * price) as u128)
            } else { 0 }
        } else { 0 }
    }

    public(friend) fun get_supply_by_user(pool_addr: address, user_addr: address): u128 acquires AptinPool {
        // BTC
        let value_btc = get_supply_by_user_cion<BTC>(pool_addr, user_addr);
        // USDT
        let value_usdt = get_supply_by_user_cion<USDT>(pool_addr, user_addr);
        // ETH
        let value_eth = get_supply_by_user_cion<ETH>(pool_addr, user_addr);
        // USDC
        let value_usdc = get_supply_by_user_cion<USDC>(pool_addr, user_addr);
        // APT
        let value_apt = get_supply_by_user_cion<AptosCoin>(pool_addr, user_addr);

        (value_btc as u128) + (value_usdt as u128) +  (value_eth as u128) + (value_usdc as u128) + (value_apt as u128)
    }

    fun get_borrow_by_user(pool_addr: address, user_addr: address): u128 acquires AptinPool {
        // BTC
        let value_btc = get_borrow_by_user_coin<BTC>(pool_addr, user_addr);
        // USDT
        let value_usdt = get_borrow_by_user_coin<USDT>(pool_addr, user_addr);
        // ETH
        let value_eth = get_borrow_by_user_coin<ETH>(pool_addr, user_addr);
        // USDC
        let value_usdc = get_borrow_by_user_coin<USDC>(pool_addr, user_addr);
        // APT
        let value_apt = get_borrow_by_user_coin<AptosCoin>(pool_addr, user_addr);

        (value_btc as u128) + (value_usdt as u128) +  (value_eth as u128) + (value_usdc as u128) + (value_apt as u128)
    }

    public(friend) fun validate_balance<CoinType>(pool_addr: address, user_addr: address, amount: u64) acquires AptinPool {
        let total_supply_user = get_supply_by_user(pool_addr, user_addr);

        let total_borrow_user = get_borrow_by_user(pool_addr, user_addr);

        let price = price::get_price<CoinType>(pool_addr);

        assert!(total_supply_user > total_borrow_user + (price * amount as u128), EINSUFFICIENT_SUPPLY);
    }

}

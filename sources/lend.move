module aptin_lend::lend {
    use std::signer;

    use aptos_framework::coin;

    use aptin_lend::price;
    use aptin_lend::res;
    use aptin_lend::vcoins;
    use aptin_lend::pool;
    use std::error;

    const ENOT_INITIALIZE_COIN_FOR_POOL: u64 = 1;
    const ENOT_INITIALIZE_POOL: u64 = 2;
    const EINSUFFICIENT_BALANCE: u64 = 3;

    public entry fun initialize_once(source: &signer, seed: vector<u8>, optional_auth_key: vector<u8>) {
        res::create_resource_account(source, seed, optional_auth_key)
    }

    /// Initialize lend-pool
    public entry fun init<CoinType>(admin: &signer, value: u64 ) {
        let admin_addr = signer::address_of(admin);
        assert!(coin::is_coin_initialized<CoinType>(), error::unavailable(ENOT_INITIALIZE_COIN_FOR_POOL));

        let pool_signer = res::get_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);

        if (!coin::is_account_registered<CoinType>(pool_addr)) {
            coin::register<CoinType>(&pool_signer);
        };

        vcoins::init_v_coin<CoinType>(admin, &pool_signer);
        
        price::initialize<CoinType>(&pool_signer, value);

        pool::init_pool<CoinType>(&pool_signer);
    }

    /// Supply
    public entry fun supply<CoinType>(user: &signer, admin_addr: address, amount: u64) {
        let user_addr = signer::address_of(user);

        let pool_signer = res::get_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);

        assert!(pool::exists_pool<CoinType>(pool_addr), error::not_found(ENOT_INITIALIZE_POOL));

        // transfer coin
        coin::transfer<CoinType>(user, pool_addr, amount);

        // update supply info of pool
        pool::increase_supply_pool<CoinType>(pool_addr, user_addr, amount);

        // transfer or MINT V-Token to user
        vcoins::transfer_v_coin<CoinType>(&pool_signer, user, amount);
    }


    /// Borrow 
    public entry fun borrow<CoinType>(user: &signer, admin_addr: address, amount: u64) {
        let user_addr = signer::address_of(user);

        let pool_signer = res::get_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);

        assert!(pool::exists_pool<CoinType>(pool_addr), error::not_found(ENOT_INITIALIZE_POOL));

        // check if user can borrow
        pool::validate_balance<CoinType>(pool_addr, user_addr, amount);

        // transfer coin to user
        if (!coin::is_account_registered<CoinType>(user_addr)) {
            coin::register<CoinType>(user);
        };

        coin::transfer<CoinType>(&pool_signer, user_addr, amount);

        // update borrow info of pool
        pool::increase_borrow_pool<CoinType>(pool_addr, user_addr, amount);

    }

    /// Withdraw coin
    public entry fun withdraw<CoinType>(user: &signer, admin_addr: address, amount: u64) {
        let user_addr = signer::address_of(user);

        let pool_signer = res::get_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);

        assert!(pool::exists_pool<CoinType>(pool_addr), error::not_found(ENOT_INITIALIZE_POOL));

        // check if withdraw is valid
        pool::validate_balance<CoinType>(pool_addr, user_addr, amount);

        // user transfer amount of v
        vcoins::transfer_v_coin<CoinType>(user, &pool_signer, amount);

        // transfer coin responding to v to user
        coin::transfer<CoinType>(&pool_signer, user_addr, amount);

        // update supply info of pool
        pool::decrease_supply_pool<CoinType>(pool_addr, user_addr, amount);
    }

    /// Repay coin
    public entry fun repay<CoinType>(user: &signer, admin_addr: address, amount: u64) {
        // transfer coin to pool
        let user_addr = signer::address_of(user);
        assert!(coin::balance<CoinType>(user_addr) >= amount, EINSUFFICIENT_BALANCE);

        let pool_signer = res::get_signer(admin_addr);
        let pool_addr = signer::address_of(&pool_signer);

        assert!(pool::exists_pool<CoinType>(pool_addr), error::not_found(ENOT_INITIALIZE_POOL));

        coin::transfer<CoinType>(user, pool_addr, amount);

        // update borrow info of pool
        pool::decrease_borrow_pool<CoinType>(pool_addr, user_addr, amount);
    }
}
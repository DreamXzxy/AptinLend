module aptin_lend::reward {
    use std::signer;
    use std::error;

    friend aptin_lend::lend;

    const EREWARD_INITIALIED: u64 = 1;
    const EREWARD_NOT_INITIALIED: u64 = 2;

    struct Reward<phantom CoinType> has key {
        value: u64
    }

    public(friend) fun init<CoinType>(account: &signer, value: u64) {
        assert!(!exists<Reward<CoinType>>(signer::address_of(account)), error::already_exists(EREWARD_INITIALIED));

        move_to(account, Reward<CoinType> {
            value
        })
    }

    public(friend) fun get_reward<CoinType>(account_addr: address): u64 acquires Reward {
        assert!(exists<Reward<CoinType>>(account_addr), error::not_found(EREWARD_NOT_INITIALIED));

        let reward = borrow_global<Reward<CoinType>>(account_addr);

        reward.value
    }

    public entry fun update_reward<CoinType>(account: &signer, value: u64) acquires Reward {
        let account_addr = signer::address_of(account);
        assert!(exists<Reward<CoinType>>(account_addr), error::not_found(EREWARD_NOT_INITIALIED));

        let reward = borrow_global_mut<Reward<CoinType>>(account_addr);

        reward.value = value;
    }
}
module aptin_lend::res {
//    use std::vector;
    use std::signer;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::error;
    //    use aptos_framework::resource_account;

    const EALREADY_EXISTS_SIGNERCAP: u64 = 0;
    const ENOT_EXISTS_SIGNERCAP: u64 = 1;

    friend aptin_lend::lend;
    friend aptin_lend::pool;
    // friend aptin_lend::price;

    struct SignerCap has key {
        signer_cap: account::SignerCapability,
    }

    public(friend) fun create_resource_account(source: &signer, seed: vector<u8>, _optional_auth_key: vector<u8>) {
        assert!(!exists<SignerCap>(signer::address_of(source)), error::already_exists(EALREADY_EXISTS_SIGNERCAP));

        let (lend_signer, lend_signer_cap) = account::create_resource_account(source, seed);

        move_to(source,
            SignerCap {
                signer_cap: lend_signer_cap
            }
        );

        coin::register<AptosCoin>(&lend_signer);
        aptos_account::transfer(source, signer::address_of(&lend_signer), 20000);

//
//        let source_addr = signer::address_of(source);
//        assert!(exists<SignerCap>(source_addr), ENOT_EXISTS_SIGNERCAP);
//
//        coin::register<AptosCoin>(&lend_signer);
//        coin::transfer<AptosCoin>(source, signer::address_of(&lend_signer), 2000);
//
//        let auth_key = if (vector::is_empty(&optional_auth_key)) {
//            account::get_authentication_key(signer::address_of(source))
//        } else {
//            optional_auth_key
//        };
//        account::rotate_authentication_key_internal(&lend_signer, auth_key);

    }

    /// 
    public(friend) fun get_signer(admin_addr: address): signer acquires SignerCap {
        assert!(exists<SignerCap>(admin_addr), ENOT_EXISTS_SIGNERCAP);
        let store = borrow_global<SignerCap>(admin_addr);
        account::create_signer_with_capability(&store.signer_cap)
    }

    // #[test(source=@0x10)]
    // public entry fun create_resource_account_test(source: &signer) {
    //     let source_addr = signer::address_of(source);
    //     account::create_account(source_addr);

    //     let seed = b"aptin";
    //     create_resource_account(source, seed, b"");
    // }

}
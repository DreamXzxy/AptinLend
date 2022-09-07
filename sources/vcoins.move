module aptin_lend::vcoins {
    use std::signer;

    use aptos_std::type_info;

    use aptos_framework::coin;
    use aptos_framework::managed_coin;

    friend aptin_lend::lend;

    struct VBTC {}

    struct VUSDT {}

    struct VETH {}

    struct VUSDC {}

    struct VAPT {}

    public(friend) fun init_v_coin<CoinType>(admin: &signer, lend_signer: &signer) {
        let type_info = type_info::type_of<CoinType>();
        let struct_name = type_info::struct_name(&type_info);

        let lend_addr = signer::address_of(lend_signer);

        if (struct_name == b"BTC") {
            if (!coin::is_account_registered<VBTC>(lend_addr)) {
                coin::register<VBTC>(lend_signer);
            };
            managed_coin::mint<VBTC>(admin, lend_addr, 10000000);
        } else if (struct_name == b"USDT") {
            if (!coin::is_account_registered<VUSDT>(lend_addr)) {
                coin::register<VUSDT>(lend_signer);
            };
            managed_coin::mint<VUSDT>(admin, lend_addr, 1000000000000);
        } else if (struct_name == b"ETH") {
            if (!coin::is_account_registered<VETH>(lend_addr)) {
                coin::register<VETH>(lend_signer);
            };
            managed_coin::mint<VETH>(admin, lend_addr, 1000000000000);
        } else if (struct_name == b"USDC") {
            if (!coin::is_account_registered<VUSDC>(lend_addr)) {
                coin::register<VUSDC>(lend_signer);
            };
            managed_coin::mint<VUSDC>(admin, lend_addr, 100000000000);
        } else if (struct_name == b"AptosCoin") {
            if (!coin::is_account_registered<VAPT>(lend_addr)) {
                coin::register<VAPT>(lend_signer);
            };
            managed_coin::mint<VAPT>(admin, lend_addr, 10000000000);
        }
    }

    public(friend) fun transfer_v_coin<CoinType>(source: &signer, dst: &signer, amount: u64) {
        let type_info = type_info::type_of<CoinType>();
        let struct_name = type_info::struct_name(&type_info);

        let dst_addr = signer::address_of(dst);

        if (struct_name == b"BTC") {
            if (!coin::is_account_registered<VBTC>(dst_addr)) {
                coin::register<VBTC>(dst);
            };
            coin::transfer<VBTC>(source, dst_addr, amount);
        } else if (struct_name == b"USDT") {
            if (!coin::is_account_registered<VUSDT>(dst_addr)) {
                coin::register<VUSDT>(dst);
            };
            coin::transfer<VUSDT>(source, dst_addr, amount);
        } else if (struct_name == b"ETH") {
            if (!coin::is_account_registered<VETH>(dst_addr)) {
                coin::register<VETH>(dst);
            };
            coin::transfer<VETH>(source, dst_addr, amount);
        } else if (struct_name == b"USDC") {
            if (!coin::is_account_registered<VUSDC>(dst_addr)) {
                coin::register<VUSDC>(dst);
            };
            coin::transfer<VUSDC>(source, dst_addr, amount);
        } else if (struct_name == b"AptosCoin") {
            if (!coin::is_account_registered<VAPT>(dst_addr)) {
                coin::register<VAPT>(dst);
            };
            coin::transfer<VAPT>(source, dst_addr, amount);
        }
    }

}
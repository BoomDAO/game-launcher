export BLOB="$(didc encode --format blob "(record {
    project = record {
        name = \"hitesh\";
        website = \"xyz\";
        bannerUrl = \"xyz\";
        description = variant { plainText = \"xyz\"};
        metadata = vec { record { \"xyz\"; \"xyz\" }; record { \"xyz\"; \"xyz\" }; };
        creator = \"xyz\";
        creatorAbout = \"xyz\";
        creatorImageUrl = \"xyz\";
    };
    token_init_arg = record {
        decimals = null;
        token_symbol = \"NUT\";
        transfer_fee = 100000 : nat;
        metadata = vec { record { \"xyz\"; variant { Text }; }; record { 1000 : int; variant { Int }; }; };
        minting_account = record {
            owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
            subaccount = null;
        };
        initial_balances = vec {};
        maximum_number_of_accounts = null;
        accounts_overflow_trim_quantity = null;
        fee_collector_account = null;
        archive_options = record {
            num_blocks_to_archive = 1000 : nat64;
            max_transactions_per_response = null;
            trigger_threshold = 1000 : nat64;
            max_message_size_bytes = null;
            cycles_for_archive_creation = null;
            node_max_memory_size_bytes = null;
            controller_id = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
        };
        max_memo_length = null;
        token_name = \"NUT\";
        feature_flags = null;
    };
})")"
echo $BLOB
dfx canister --network ic call w73yo-siaaa-aaaak-qib2q-cai validate_create_icrc_token "(record {
    project = record {
        name = \"hitesh\" : text;
        website = \"xyz\" : text;
        bannerUrl = \"xyz\" : text;
        description = variant { plainText = \"xyz\"};
        metadata = vec { record { \"xyz\"; \"xyz\" }; record { \"xyz\"; \"xyz\" }; };
        creator = \"xyz\" : text;
        creatorAbout = \"xyz\" : text;
        creatorImageUrl = \"xyz\" : text;
    };
    token_init_arg = record {
        decimals = null;
        token_symbol = \"NUT\";
        transfer_fee = 100000 : nat;
        metadata = vec { record { \"xyz\"; variant { Text = \"xyz\" }; }; record { \"xyz\"; variant { Int = 1000 : int }; }; };
        minting_account = record {
            owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
            subaccount = null;
        };
        initial_balances = vec {};
        maximum_number_of_accounts = null;
        accounts_overflow_trim_quantity = null;
        fee_collector_account = null;
        archive_options = record {
            num_blocks_to_archive = 1000 : nat64;
            max_transactions_per_response = null;
            trigger_threshold = 1000 : nat64;
            max_message_size_bytes = null;
            cycles_for_archive_creation = null;
            node_max_memory_size_bytes = null;
            controller_id = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
        };
        max_memo_length = null;
        token_name = \"NUT\";
        feature_flags = null;
    };
})"
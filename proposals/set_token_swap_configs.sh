#all the token values listed below must be in e8s
#Other : in supply configs is allocation to some specific entity in case some project team wants to allocate
export BLOB="$(didc encode --format blob "( record {
    configs = record {
        token_supply_configs = record { 
            gaming_guilds = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            participants = record {
                icrc = 1000 : nat;
            };
            team = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            boom_dao_treasury = record {
                icp_account = \"xyz\" : text;
                icrc_account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64;
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            liquidity_pool = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            other = opt record { 
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
        };
        min_token_e8s = 1000 : nat64;
        max_token_e8s = 1000 : nat64;
        min_participant_token_e8s = 1000 : nat64;
        max_participant_token_e8s = 1000 : nat64;
        swap_start_timestamp_seconds = 1000 : int;
        swap_due_timestamp_seconds = 1000 : int;
        swap_type = variant { boom };
    };
    canister_id = \"xyz\";
} )")"
echo $BLOB

dfx canister --network ic call w73yo-siaaa-aaaak-qib2q-cai validate_set_token_swap_configs "(record {
    configs = record {
        token_supply_configs = record { 
            gaming_guilds = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            participants = record {
                icrc = 1000 : nat;
            };
            team = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            boom_dao_treasury = record {
                icp_account = \"xyz\" : text;
                icrc_account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64;
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            liquidity_pool = record {
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
            other = opt record { 
                account = record {
                    owner = principal \"w73yo-siaaa-aaaak-qib2q-cai\";
                    subaccount = null;
                };
                icp = 1000 : nat64; 
                boom = 1000 : nat;
                icrc = 1000 : nat;
                icp_result = null;
                boom_result = null;
                icrc_result = null;
            };
        };
        min_token_e8s = 1000 : nat64;
        max_token_e8s = 1000 : nat64;
        min_participant_token_e8s = 1000 : nat64;
        max_participant_token_e8s = 1000 : nat64;
        swap_start_timestamp_seconds = 1000 : int;
        swap_due_timestamp_seconds = 1000 : int;
        swap_type = variant { boom };
    };
    canister_id = \"xyz\";
})"
export PRINCIPAL="2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe" # Controller Principal 
export FEE=10 # TX fee of Token
export SYMBOL="BOOM" # Token Symbol
export NAME="BOOM" # Token Name
 
# dfx deploy --mode reinstall icrc-ledger --argument "(variant {
#     Init = record {
#         minting_account = record { owner = principal \"$PRINCIPAL\" };
#         transfer_fee = $FEE;
#         token_symbol = \"$SYMBOL\";
#         token_name = \"$NAME\";
#         metadata = vec {};
#         initial_balances = vec {};
#         archive_options = record {
#             num_blocks_to_archive = 2000;
#             trigger_threshold = 1000;
#             cycles_for_archive_creation = opt 4_000_000_000_000;
#             controller_id = principal \"$PRINCIPAL\";
#         };
#     }
# })"

dfx canister --network stag call swap create_icrc_token '(record {
    decimals : ?Nat8;
    token_symbol : Text;
    transfer_fee : Nat;
    metadata : [];
    minting_account : Account;
    initial_balances : [(Account, Nat)];
    maximum_number_of_accounts : ?Nat64;
    accounts_overflow_trim_quantity : ?Nat64;
    fee_collector_account : ?Account;
    archive_options : {
      num_blocks_to_archive : Nat64;
      max_transactions_per_response : ?Nat64;
      trigger_threshold : Nat64;
      max_message_size_bytes : ?Nat64;
      cycles_for_archive_creation : ?Nat64;
      node_max_memory_size_bytes : ?Nat64;
      controller_id : Principal;
    };
    max_memo_length : ?Nat16;
    token_name : Text;
    feature_flags : ?FeatureFlags;
})'
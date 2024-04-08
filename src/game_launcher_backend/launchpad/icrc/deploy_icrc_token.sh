export FEE=10 # TX fee of Token
export SYMBOL="DEMO" # Token Symbol
export NAME="DEMO" # Token Name
export PRINCIPAL=$(dfx identity get-principal)

dfx deploy icrc_ledger --network stag --mode reinstall --argument "(variant {
  Init = record {
     token_symbol = \"DEMO\";
     token_name = \"Demo Token\";
     minting_account = record { owner = principal \"$PRINCIPAL\" };
     transfer_fee = 100;
     metadata = vec {};
     initial_balances = vec {};
     archive_options = record {
         num_blocks_to_archive = 10_000;
         trigger_threshold = 20_000;
         controller_id = principal \"$PRINCIPAL\";
         cycles_for_archive_creation = opt 1_000_000_000_000;
         max_message_size_bytes = null;
         node_max_memory_size_bytes = opt 3_221_225_472;
     };
     feature_flags  = opt record { icrc2 = true };
 }
})"
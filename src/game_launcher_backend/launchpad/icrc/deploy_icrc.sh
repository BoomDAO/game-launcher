export PRINCIPAL="2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe" # Controller Principal 
export FEE=10 # TX fee of Token
export SYMBOL="BOOM" # Token Symbol
export NAME="BOOM" # Token Name
 
dfx deploy --mode reinstall icrc-ledger --argument "(variant {
    Init = record {
        minting_account = record { owner = principal \"$PRINCIPAL\" };
        transfer_fee = $FEE;
        token_symbol = \"$SYMBOL\";
        token_name = \"$NAME\";
        metadata = vec {};
        initial_balances = vec {};
        archive_options = record {
            num_blocks_to_archive = 2000;
            trigger_threshold = 1000;
            cycles_for_archive_creation = opt 4_000_000_000_000;
            controller_id = principal \"$PRINCIPAL\";
        };
    }
})"
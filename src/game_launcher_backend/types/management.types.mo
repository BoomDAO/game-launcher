module {
    //Types
    public type user_id = Principal;
    public type bitcoin_address = Text;
    public type bitcoin_network = { #mainnet; #testnet };
    public type block_hash = [Nat8];
    public type canister_id = Principal;
    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type change = {
        timestamp_nanos : Nat64;
        canister_version : Nat64;
        origin : change_origin;
        details : change_details;
    };
    public type change_details = {
        #creation : { controllers : [Principal] };
        #code_deployment : {
            mode : { #reinstall; #upgrade; #install };
            module_hash : [Nat8];
        };
        #controllers_change : { controllers : [Principal] };
        #code_uninstall;
    };
    public type change_origin = {
        #from_user : { user_id : Principal };
        #from_canister : { canister_version : ?Nat64; canister_id : Principal };
    };
    public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    public type ecdsa_curve = { #secp256k1 };
    public type get_balance_request = {
        network : bitcoin_network;
        address : bitcoin_address;
        min_confirmations : ?Nat32;
    };
    public type get_current_fee_percentiles_request = {
        network : bitcoin_network;
    };
    public type get_utxos_request = {
        network : bitcoin_network;
        filter : ?{ #page : [Nat8]; #min_confirmations : Nat32 };
        address : bitcoin_address;
    };
    public type get_utxos_response = {
        next_page : ?[Nat8];
        tip_height : Nat32;
        tip_block_hash : block_hash;
        utxos : [utxo];
    };
    public type http_header = { value : Text; name : Text };
    public type http_response = {
        status : Nat;
        body : [Nat8];
        headers : [http_header];
    };
    public type millisatoshi_per_byte = Nat64;
    public type outpoint = { txid : [Nat8]; vout : Nat32 };
    public type satoshi = Nat64;
    public type send_transaction_request = {
        transaction : [Nat8];
        network : bitcoin_network;
    };
    public type utxo = { height : Nat32; value : satoshi; outpoint : outpoint };
    public type wasm_module = Blob;
    public type headerField = (Text, Text);
    public type HttpRequest = {
        body : Blob;
        headers : [headerField];
        method : Text;
        url : Text;
    };
    public type HttpResponse = {
        body : Blob;
        headers : [headerField];
        status_code : Nat16;
    };

    //IC Management Canister
    public type Management = actor {
        canister_status : shared { canister_id : canister_id } -> async {
            status : { #stopped; #stopping; #running };
            memory_size : Nat;
            cycles : Nat;
            settings : definite_canister_settings;
            module_hash : ?[Nat8];
        };
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        delete_canister : shared { canister_id : canister_id } -> async ();
        deposit_cycles : shared { canister_id : canister_id } -> async ();
        install_code : shared {
            arg : Blob;
            wasm_module : wasm_module;
            mode : { #reinstall; #upgrade : ? {
                skip_pre_upgrade : ?Bool;
            }; #install };
            canister_id : canister_id;
        } -> async ();
        provisional_create_canister_with_cycles : shared {
            settings : ?canister_settings;
            amount : ?Nat;
        } -> async { canister_id : canister_id };
        provisional_top_up_canister : shared {
            canister_id : canister_id;
            amount : Nat;
        } -> async ();
        raw_rand : shared () -> async [Nat8];
        start_canister : shared { canister_id : canister_id } -> async ();
        stop_canister : shared { canister_id : canister_id } -> async ();
        uninstall_code : shared { canister_id : canister_id } -> async ();
        update_settings : shared {
            canister_id : Principal;
            settings : canister_settings;
        } -> async ();
    };
};

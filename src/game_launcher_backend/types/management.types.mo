module {
  public type StreamingCallbackHttpResponse = {
    body : Blob;
    token : ?Token;
  };
  public type Token = {
    arbitrary_data : Text;
  };
  public type CallbackStrategy = {
    callback : shared query (Token) -> async StreamingCallbackHttpResponse;
    token : Token;
  };
  public type StreamingStrategy = {
    #Callback : CallbackStrategy;
  };
  public type HeaderField = (Text, Text);
  public type HttpResponse = {
    status_code : Nat16;
    headers : [HeaderField];
    body : Blob;
  };
  public type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
  };
  public type bitcoin_address = Text;
  public type bitcoin_network = { #mainnet; #testnet };
  public type block_hash = Blob;
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
      module_hash : Blob;
    };
    #controllers_change : { controllers : [Principal] };
    #code_uninstall;
  };
  public type change_origin = {
    #from_user : { user_id : Principal };
    #from_canister : { canister_version : ?Nat64; canister_id : Principal };
  };
  public type chunk_hash = Blob;
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
    filter : ?{ #page : Blob; #min_confirmations : Nat32 };
    address : bitcoin_address;
  };
  public type get_utxos_response = {
    next_page : ?Blob;
    tip_height : Nat32;
    tip_block_hash : block_hash;
    utxos : [utxo];
  };
  public type http_header = { value : Text; name : Text };
  public type http_response = {
    status : Nat;
    body : Blob;
    headers : [http_header];
  };
  public type millisatoshi_per_byte = Nat64;
  public type outpoint = { txid : Blob; vout : Nat32 };
  public type satoshi = Nat64;
  public type send_transaction_request = {
    transaction : Blob;
    network : bitcoin_network;
  };
  public type utxo = { height : Nat32; value : satoshi; outpoint : outpoint };
  public type wasm_module = Blob;
  public type Self = actor {
    bitcoin_get_balance : shared get_balance_request -> async satoshi;
    bitcoin_get_balance_query : shared query get_balance_request -> async satoshi;
    bitcoin_get_current_fee_percentiles : shared get_current_fee_percentiles_request -> async [
      millisatoshi_per_byte
    ];
    bitcoin_get_utxos : shared get_utxos_request -> async get_utxos_response;
    bitcoin_get_utxos_query : shared query get_utxos_request -> async get_utxos_response;
    bitcoin_send_transaction : shared send_transaction_request -> async ();
    canister_info : shared {
      canister_id : canister_id;
      num_requested_changes : ?Nat64;
    } -> async {
      controllers : [Principal];
      module_hash : ?Blob;
      recent_changes : [change];
      total_num_changes : Nat64;
    };
    canister_status : shared { canister_id : canister_id } -> async {
      status : { #stopped; #stopping; #running };
      memory_size : Nat;
      cycles : Nat;
      settings : definite_canister_settings;
      idle_cycles_burned_per_day : Nat;
      module_hash : ?Blob;
    };
    clear_chunk_store : shared { canister_id : canister_id } -> async ();
    create_canister : shared {
      settings : ?canister_settings;
      sender_canister_version : ?Nat64;
    } -> async { canister_id : canister_id };
    delete_canister : shared { canister_id : canister_id } -> async ();
    deposit_cycles : shared { canister_id : canister_id } -> async ();
    ecdsa_public_key : shared {
      key_id : { name : Text; curve : ecdsa_curve };
      canister_id : ?canister_id;
      derivation_path : [Blob];
    } -> async { public_key : Blob; chain_code : Blob };
    http_request : shared {
      url : Text;
      method : { #get; #head; #post };
      max_response_bytes : ?Nat64;
      body : ?Blob;
      transform : ?{
        function : shared query {
          context : Blob;
          response : http_response;
        } -> async http_response;
        context : Blob;
      };
      headers : [http_header];
    } -> async http_response;
    install_chunked_code : shared {
      arg : Blob;
      wasm_module_hash : Blob;
      mode : {
        #reinstall;
        #upgrade : ?{ skip_pre_upgrade : ?Bool };
        #install;
      };
      chunk_hashes_list : [chunk_hash];
      target_canister : canister_id;
      sender_canister_version : ?Nat64;
      storage_canister : ?canister_id;
    } -> async ();
    install_code : shared {
      arg : Blob;
      wasm_module : wasm_module;
      mode : {
        #reinstall;
        #upgrade : ?{ skip_pre_upgrade : ?Bool };
        #install;
      };
      canister_id : canister_id;
      sender_canister_version : ?Nat64;
    } -> async ();
    provisional_create_canister_with_cycles : shared {
      settings : ?canister_settings;
      specified_id : ?canister_id;
      amount : ?Nat;
      sender_canister_version : ?Nat64;
    } -> async { canister_id : canister_id };
    provisional_top_up_canister : shared {
      canister_id : canister_id;
      amount : Nat;
    } -> async ();
    raw_rand : shared () -> async Blob;
    sign_with_ecdsa : shared {
      key_id : { name : Text; curve : ecdsa_curve };
      derivation_path : [Blob];
      message_hash : Blob;
    } -> async { signature : Blob };
    start_canister : shared { canister_id : canister_id } -> async ();
    stop_canister : shared { canister_id : canister_id } -> async ();
    stored_chunks : shared { canister_id : canister_id } -> async [chunk_hash];
    uninstall_code : shared {
      canister_id : canister_id;
      sender_canister_version : ?Nat64;
    } -> async ();
    update_settings : shared {
      canister_id : Principal;
      settings : canister_settings;
      sender_canister_version : ?Nat64;
    } -> async ();
    upload_chunk : shared {
      chunk : Blob;
      canister_id : Principal;
    } -> async chunk_hash;
  };
};

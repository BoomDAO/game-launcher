module AssetStorage {
  public type AssetDetails = {
    key : Key;
    encodings : [AssetEncodingDetails];
    content_type : Text;
  };
  public type AssetEncodingDetails = {
    modified : Time;
    sha256 : ?[Nat8];
    length : Nat;
    content_encoding : Text;
  };
  public type BatchId = Nat32;
  public type BatchOperationKind = {
    #CreateAsset : CreateAssetArguments;
    #UnsetAssetContent : UnsetAssetContentArguments;
    #DeleteAsset : DeleteAssetArguments;
    #SetAssetContent : SetAssetContentArguments;
    #Clear : ClearArguments;
  };
  public type ChunkId = Nat32;
  public type ClearArguments = {};
  public type CommitBatchArguments = {
    batch_id : BatchId;
    operations : [BatchOperationKind];
  };
  public type Contents = [Nat8];
  public type CreateAssetArguments = { key : Key; content_type : Text };
  public type DeleteAssetArguments = { key : Key };
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    streaming_strategy : ?StreamingStrategy;
    status_code : Nat16;
  };
  public type Key = Text;
  public type Path = Text;
  public type SetAssetContentArguments = {
    key : Key;
    sha256 : ?[Nat8];
    chunk_ids : [ChunkId];
    content_encoding : Text;
  };
  public type StreamingCallbackHttpResponse = {
    token : ?StreamingCallbackToken;
    body : [Nat8];
  };
  public type StreamingCallbackToken = {
    key : Text;
    sha256 : ?[Nat8];
    index : Nat;
    content_encoding : Text;
  };
  public type StreamingStrategy = {
    #Callback : {
      token : StreamingCallbackToken;
      callback : shared query StreamingCallbackToken -> async StreamingCallbackHttpResponse;
    };
  };
  public type Time = Int;
  public type UnsetAssetContentArguments = {
    key : Key;
    content_encoding : Text;
  };
  public type Self = actor {
    authorize : shared Principal -> async ();
    clear : shared ClearArguments -> async ();
    commit_batch : shared CommitBatchArguments -> async ();
    create_asset : shared CreateAssetArguments -> async ();
    create_batch : shared {} -> async { batch_id : BatchId };
    create_chunk : shared { content : [Nat8]; batch_id : BatchId } -> async {
        chunk_id : ChunkId;
      };
    delete_asset : shared DeleteAssetArguments -> async ();
    get : shared query { key : Key; accept_encodings : [Text] } -> async {
        content : [Nat8];
        sha256 : ?[Nat8];
        content_type : Text;
        content_encoding : Text;
        total_length : Nat;
      };
    get_chunk : shared query {
        key : Key;
        sha256 : ?[Nat8];
        index : Nat;
        content_encoding : Text;
      } -> async { content : [Nat8] };
    http_request : shared query HttpRequest -> async HttpResponse;
    http_request_streaming_callback : shared query StreamingCallbackToken -> async StreamingCallbackHttpResponse;
    list : shared query {} -> async [AssetDetails];
    retrieve : shared query Path -> async Contents;
    set_asset_content : shared SetAssetContentArguments -> async ();
    store : shared {
        key : Key;
        content : [Nat8];
        sha256 : ?[Nat8];
        content_type : Text;
        content_encoding : Text;
      } -> async ();
    unset_asset_content : shared UnsetAssetContentArguments -> async ();
  }
}

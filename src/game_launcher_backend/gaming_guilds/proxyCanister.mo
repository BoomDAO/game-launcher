module {
  public type CanisterCallbackMethodName = Text;
  public type CanisterId = Principal;
  public type CanisterOutputCertifiedMessages = {
    messages : [CanisterOutputMessage];
    cert : Blob;
    tree : Blob;
    is_end_of_queue : Bool;
  };
  public type CanisterOutputMessage = {
    key : Text;
    content : Blob;
    client_key : ClientKey;
  };
  public type CanisterRequest = {
    canister_id : CanisterId;
    state : RequestState;
  };
  public type CanisterWsCloseArguments = { client_key : ClientKey };
  public type CanisterWsCloseResult = { #Ok; #Err : Text };
  public type CanisterWsGetMessagesArguments = { nonce : Nat64 };
  public type CanisterWsGetMessagesResult = {
    #Ok : CanisterOutputCertifiedMessages;
    #Err : Text;
  };
  public type CanisterWsMessageArguments = { msg : WebsocketMessage };
  public type CanisterWsMessageResult = { #Ok; #Err : Text };
  public type CanisterWsOpenArguments = {
    gateway_principal : GatewayPrincipal;
    client_nonce : Nat64;
  };
  public type CanisterWsOpenResult = { #Ok; #Err : Text };
  public type ClientKey = {
    client_principal : ClientPrincipal;
    client_nonce : Nat64;
  };
  public type ClientPrincipal = Principal;
  public type GatewayPrincipal = Principal;
  public type HttpFailureReason = { #ProxyError : Text; #RequestTimeout };
  public type HttpHeader = { value : Text; name : Text };
  public type HttpMethod = { #GET; #PUT; #DELETE; #HEAD; #POST };
  public type HttpOverWsError = {
    #NotHttpOverWsType : Text;
    #ProxyNotFound;
    #NotYetReceived;
    #ConnectionNotAssignedToProxy;
    #RequestIdNotFound;
    #NoProxiesConnected;
    #InvalidHttpMessage;
    #RequestFailed : HttpFailureReason;
  };
  public type HttpOverWsMessage = {
    #Error : (?HttpRequestId, Text);
    #HttpRequest : (HttpRequestId, HttpRequest);
    #SetupProxyClient;
    #HttpResponse : (HttpRequestId, HttpResponse);
  };
  public type HttpRequest = {
    url : Text;
    method : HttpMethod;
    body : ?Blob;
    headers : [HttpHeader];
  };
  public type HttpRequestEndpointArgs = {
    request : HttpRequest;
    timeout_ms : ?HttpRequestTimeoutMs;
    callback_method_name : ?CanisterCallbackMethodName;
  };
  public type HttpRequestEndpointResult = {
    #Ok : HttpRequestId;
    #Err : ProxyCanisterError;
  };
  public type HttpRequestId = Nat64;
  public type HttpRequestTimeoutMs = Nat64;
  public type HttpResponse = {
    status : Nat;
    body : Blob;
    headers : [HttpHeader];
  };
  public type InvalidRequest = {
    #TooManyHeaders;
    #InvalidTimeout;
    #InvalidUrl : Text;
  };
  public type ProxyCanisterError = {
    #HttpOverWs : HttpOverWsError;
    #InvalidRequest : InvalidRequest;
  };
  public type RequestState = {
    #Executing : ?CanisterCallbackMethodName;
    #Executed;
    #CallbackFailed : Text;
  };
  public type WebsocketMessage = {
    sequence_num : Nat64;
    content : Blob;
    client_key : ClientKey;
    timestamp : Nat64;
    is_service_message : Bool;
  };
  public type Proxy = actor {
    http_request : shared HttpRequestEndpointArgs -> async HttpRequestEndpointResult;
  }
}
module {

    // from https://github.com/dfinity/interface-spec/blob/master/spec/ic.did
    public type HttpHeader = { name: Text; value: Text };

    public type HttpResponse = {
        status: Nat;
        headers: [HttpHeader];
        body: Blob;
    };

    public let ic = actor "aaaaa-aa" : actor {
        http_request : {
            url : Text;
            max_response_bytes: ?Nat64;
            method : { #get; #head; #post };
            headers: [HttpHeader];
            body : ?Blob;
            transform : ?{
                function : shared query ({response: HttpResponse; context : Blob}) -> async (HttpResponse);
                context : Blob;
            };
        } -> async HttpResponse;
   };

}
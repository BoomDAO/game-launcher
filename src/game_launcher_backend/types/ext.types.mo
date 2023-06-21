import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Bool "mo:base/Bool";
import Int8 "mo:base/Int8";
import Int16 "mo:base/Int16";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Nat64 "mo:base/Nat64";

module {
    public type AccountIdentifier = Text;
    public type TokenIndex = Nat32;
    public type TokenIdentifier  = Text;
    public type Metadata = {
        #fungible : {
            name : Text;
            symbol : Text;
            decimals : Nat8;
            metadata : ?MetadataContainer;
        };
        #nonfungible : {
            name : Text;
            asset : Text;
            thumbnail : Text;
            metadata : ?MetadataContainer;
        };
    };
    public type MetadataContainer = {
        #data : [MetadataValue];
        #blob : Blob;
        #json : Text;
    };
    public type MetadataValue = (
        Text,
        {
            #text : Text;
            #blob : Blob;
            #nat : Nat;
            #nat8 : Nat8;
        },
    );

    public type MintingRequest = {
        to : AccountIdentifier;
        asset : Nat32;
    };

    //Marketplace
    public type Transaction = {
        token : TokenIndex;
        seller : AccountIdentifier;
        price : Nat64;
        buyer : AccountIdentifier;
        time : Int;
    };
    public type Listing = {
        seller : Principal;
        price : Nat64;
        locked : ?Int;
    };

    //LEDGER
    public type AccountBalanceArgs = { account : AccountIdentifier };
    public type ICPTs = { e8s : Nat64 };

    //Cap
    public type CapDetailValue = {
        #I64 : Int64;
        #U64 : Nat64;
        #Vec : [CapDetailValue];
        #Slice : [Nat8];
        #Text : Text;
        #True;
        #False;
        #Float : Float;
        #Principal : Principal;
    };
    public type CapEvent = {
        time : Nat64;
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };
    public type CapIndefiniteEvent = {
        operation : Text;
        details : [(Text, CapDetailValue)];
        caller : Principal;
    };

    //EXTv2 Asset Handling
    public type AssetHandle = Text;
    public type AssetId = Nat32;
    public type ChunkId = Nat32;
    public type AssetType = {
        #canister : {
            id : AssetId;
            canister : Text;
        };
        #direct : [ChunkId];
        #other : Text;
    };
    public type Asset = {
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };
    public type Asset_req = {
        assetHandle : Text;
        ctype : Text;
        filename : Text;
        atype : AssetType;
    };

    //HTTP
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
        streaming_strategy : ?StreamingStrategy;
        upgrade : ?Bool;
    };
    public type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };

    public type CommonError = {
        #InvalidToken : TokenIdentifier;
        #Other : Text;
    };

};

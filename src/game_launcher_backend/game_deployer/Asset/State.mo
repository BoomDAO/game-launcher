import AssetStorage "AssetStorage";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
module {
    public type Asset = {
        content_type : Text;
        encodings : Trie.Trie<Text, AssetEncoding>;
    };

    public type StableAsset = {
        content_type : Text;
        encodings : [(Text, AssetEncoding)];
    };

    public type AssetEncoding = {
        modified : Int;
        content_chunks : [[Nat8]];
        total_length : Nat;
        certified : Bool;
        sha256 : [Nat8];
    };

    public type Chunk = {
        batch_id : AssetStorage.BatchId;
        content : [Nat8];
    };

    public type Batch = {
        expires_at : Int;
    };
};

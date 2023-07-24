import AssetStorage "AssetStorage";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

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

    public class State(
        stableAuthorized : [Principal],
        stableAssets : [(AssetStorage.Key, StableAsset)],
    ) {
        public func keyT(x : Text) : Trie.Key<Text> {
            return { hash = Text.hash(x); key = x };
        };
        public func key(x : Nat32) : Trie.Key<Nat32> {
            return { hash = x; key = x };
        };
        public var assets : Trie.Trie<AssetStorage.Key, Asset> = Trie.empty();
        for ((k, v) in stableAssets.vals()) {
            var encodings : Trie.Trie<Text, AssetEncoding> = Trie.empty();
            for ((k, e) in v.encodings.vals()) {
                encodings := Trie.put(encodings, keyT(k), Text.equal, e).0;
            };
            assets := Trie.put(
                assets,
                keyT(k),
                Text.equal,
                {
                    content_type = v.content_type;
                    encodings;
                },
            ).0;
        };

        public var chunks : Trie.Trie<AssetStorage.ChunkId, Chunk> = Trie.empty();

        var nextChunkID : AssetStorage.ChunkId = 1;

        public func chunkID() : AssetStorage.ChunkId {
            var cID = nextChunkID;
            nextChunkID += 1;
            cID;
        };

        public var batches : Trie.Trie<AssetStorage.BatchId, Batch> = Trie.empty();

        var nextBatchID : AssetStorage.BatchId = 1;

        public func batchID() : AssetStorage.BatchId {
            var bID = nextBatchID;
            nextBatchID += 1;
            bID;
        };

        public var authorized : [Principal] = stableAuthorized;

        public func isAuthorized(p : Principal) : Result.Result<(), Text> {
            for (a in authorized.vals()) {
                if (a == p) return #ok();
            };
            #err("caller is not authorized");
        };
    };
};

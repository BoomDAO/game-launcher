import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Order "mo:base/Order";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Prim "mo:⛔";

import State "State";
import AssetStorage "AssetStorage";
import SHA256 "../../utils/SHA256";

actor class Assets() = this {
    private let BATCH_EXPIRY_NANOS = 300_000_000_000;
    private let owner : Principal = Principal.fromText("lgjp4-nfvab-rl4wt-77he2-3hnxe-24pvi-7rykv-6yyr4-sqwdd-4j2fz-fae");
    private stable var authorized : [Principal] = [owner];
    private stable var etags : Trie.Trie<Text, Text> = Trie.empty();
    private stable var assets : Trie.Trie<AssetStorage.Key, State.Asset> = Trie.empty();
    private stable var chunks : Trie.Trie<AssetStorage.ChunkId, State.Chunk> = Trie.empty();
    private stable var batches : Trie.Trie<AssetStorage.BatchId, State.Batch> = Trie.empty();

    var nextChunkID : AssetStorage.ChunkId = 1;
    var nextBatchID : AssetStorage.BatchId = 1;
    func chunkID() : AssetStorage.ChunkId {
        var cID = nextChunkID;
        nextChunkID += 1;
        cID;
    };
    func batchID() : AssetStorage.BatchId {
        var bID = nextBatchID;
        nextBatchID += 1;
        bID;
    };
    func isAuthorized(p : Principal) : Result.Result<(), Text> {
        for (a in authorized.vals()) {
            if (a == p) return #ok();
        };
        #err("caller is not authorized");
    };
    func keyT(x : Text) : Trie.Key<Text> {
            return { hash = Text.hash(x); key = x };
        };
    func key(x : Nat32) : Trie.Key<Nat32> {
        return { hash = x; key = x };
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public shared ({ caller }) func authorize(p : Principal) : async () {
        var b = Buffer.Buffer<Principal>(0);
        switch (isAuthorized(caller)) {
            case (#err(e)) throw Error.reject(e);
            case (#ok()) {
                for (a in authorized.vals()) {
                    if (a == p) {return}
                    else b.add(a);
                };
                b.add(p);
                authorized := Buffer.toArray(b);
            };
        };
    };

    public shared ({ caller }) func clear(
        a : AssetStorage.ClearArguments,
    ) : async () {
        switch (isAuthorized(caller)) {
            case (#err(e)) throw Error.reject(e);
            case (#ok()) {
                _clear();
            };
        };
    };

    private func _clear() {
        assets := Trie.empty();
        chunks := Trie.empty();
        batches := Trie.empty();
        etags := Trie.empty();
        nextChunkID := 1;
        nextBatchID := 1;
    };

    public shared ({ caller }) func commit_batch(
        a : AssetStorage.CommitBatchArguments,
    ) : async () {
        switch (isAuthorized(caller)) {
            case (#err(e)) throw Error.reject(e);
            case (#ok()) {
                let batch_id = a.batch_id;
                for (operation in a.operations.vals()) {
                    switch (operation) {
                        case (#Clear(_)) _clear();
                        case (#CreateAsset(a)) {
                            switch (_create_asset(a)) {
                                case (#err(e)) throw Error.reject(e);
                                case (#ok()) {};
                            };
                        };
                        case (#DeleteAsset(a)) {
                        };
                        case (#SetAssetContent(a)) {
                            switch (_set_asset_content(a)) {
                                case (#err(e)) throw Error.reject(e);
                                case (#ok()) {};
                            };
                        };
                        case (#UnsetAssetContent(a)) {
                        };
                    };
                };
            };
        };
    };

    private func _create_asset(
        a : AssetStorage.CreateAssetArguments,
    ) : Result.Result<(), Text> {
        switch (Trie.find(assets, keyT(a.key), Text.equal)) {
            case (null) {
                assets := Trie.put(assets, keyT(a.key), Text.equal, {
                    content_type = a.content_type;
                    encodings = Trie.empty();
                }).0;
            };
            case (?asset) {
                if (asset.content_type != a.content_type) {
                    return #err("content type mismatch");
                };
            };
        };
        #ok();
    };

    public shared ({ caller }) func create_batch() : async {
        batch_id : AssetStorage.BatchId;
    } {
        switch (isAuthorized(caller)) {
            case (#err(e)) throw Error.reject(e);
            case (#ok()) {
                let batch_id = batchID();
                let now = Time.now();
                batches := Trie.put(batches, key(batch_id), Nat32.equal, {
                        expires_at = now + BATCH_EXPIRY_NANOS;
                    }).0;
                for ((k, b) in Trie.iter(batches)) {
                    if (now > b.expires_at) batches := Trie.remove(batches, key(k), Nat32.equal).0;
                };
                for ((k, c) in Trie.iter(chunks)) {
                    switch (Trie.find(chunks, key(c.batch_id), Nat32.equal)) {
                        case (null) {
                            chunks := Trie.remove(chunks, key(k), Nat32.equal).0;
                        };
                        case (?batch) {};
                    };
                };
                { batch_id };
            };
        };
    };

    public shared ({ caller }) func create_chunk({
        content : [Nat8];
        batch_id : AssetStorage.BatchId;
    }) : async {
        chunk_id : AssetStorage.ChunkId;
    } {
        switch (isAuthorized(caller)) {
            case (#err(e)) throw Error.reject(e);
            case (#ok()) {
                switch (Trie.find(batches, key(batch_id), Nat32.equal)) {
                    case (null) throw Error.reject("batch not found: " # Nat32.toText(batch_id));
                    case (?batch) {
                        batches := Trie.put(batches, key(batch_id), Nat32.equal, {
                                expires_at = Time.now() + BATCH_EXPIRY_NANOS;
                            }).0;
                        let chunk_id = chunkID();
                        chunks := Trie.put(chunks, key(chunk_id), Nat32.equal, {
                            batch_id; content;
                        }).0;
                        { chunk_id };
                    };
                };
            };
        };
    };

    public shared query ({ caller }) func http_request(
        r : AssetStorage.HttpRequest,
    ) : async AssetStorage.HttpResponse {
        let encodings = Buffer.Buffer<Text>(r.headers.size());
        for ((k, v) in r.headers.vals()) {
            if (textToLower(k) == "accept-encoding") {
                for (v in Text.split(v, #text(","))) {
                    encodings.add(v);
                };
            };
        };

        encodings.add("identity"); //for standard files
        encodings.add("br");       //for brotli compressed files
        encodings.add("gzip");     //for gzip compressed files

        // TODO: url decode + remove path.
        switch (Trie.find(assets, keyT(r.url), Text.equal)) {
            case (null) {};
            case (?asset) {
                for (encoding_name in encodings.vals()) {
                    switch (Trie.find(asset.encodings, keyT(encoding_name), Text.equal)) {
                        case (null) {};
                        case (?encoding) {
                            let etag : Text = get_etag(r.url);
                            var if_none_match : Text = "";
                            for(i in (r.headers).vals()){
                                if(i.0 == "if-none-match"){
                                    if_none_match := i.1;
                                }
                            };
                            if(etag == "not found"){
                                let headers = [
                                    ("Content-Type", asset.content_type),
                                    ("Content-Encoding", encoding_name),
                                ];
                                return {
                                    body = encoding.content_chunks[0];
                                    headers;
                                    status_code = 200;
                                    streaming_strategy = _create_strategy(
                                        r.url,
                                        0,
                                        asset,
                                        encoding_name,
                                        encoding,
                                    );
                                };
                            } else if(etag != if_none_match and etag != "not found"){
                                let headers = [
                                    ("Content-Type", asset.content_type),
                                    ("Content-Encoding", encoding_name),
                                    ("ETag", etag),
                                ];
                                return {
                                    body = encoding.content_chunks[0];
                                    headers;
                                    status_code = 200;
                                    streaming_strategy = _create_strategy(
                                        r.url,
                                        0,
                                        asset,
                                        encoding_name,
                                        encoding,
                                    );
                                };
                            } else if(etag == if_none_match){
                                let headers = [
                                    ("Content-Type", asset.content_type),
                                    ("Content-Encoding", encoding_name),
                                    ("ETag", etag),
                                ];
                                return {
                                    body = [];
                                    headers;
                                    status_code = 304;
                                    streaming_strategy = _create_strategy(
                                        r.url,
                                        0,
                                        asset,
                                        encoding_name,
                                        encoding,
                                    );
                                };
                            } else {
                                let headers = [
                                    ("Content-Type", asset.content_type),
                                    ("Content-Encoding", encoding_name),
                                ];
                                return {
                                    body = encoding.content_chunks[0];
                                    headers;
                                    status_code = 200;
                                    streaming_strategy = _create_strategy(
                                        r.url,
                                        0,
                                        asset,
                                        encoding_name,
                                        encoding,
                                    );
                                };
                            }
                        };
                    };
                };
            };
        };
        {
            body = Blob.toArray(Text.encodeUtf8("asset not found: " # r.url));
            headers = [];
            streaming_strategy = null;
            status_code = 404;
        };
    };

    private func _create_strategy(
        key : Text,
        index : Nat,
        asset : State.Asset,
        encoding_name : Text,
        encoding : State.AssetEncoding,
    ) : ?AssetStorage.StreamingStrategy {
        switch (_create_token(key, index, asset, encoding_name, encoding)) {
            case (null) { null };
            case (?token) {
                ?#Callback({
                    token;
                    callback = http_request_streaming_callback;
                });
            };
        };
    };

    private func textToLower(t : Text) : Text {
        Text.map(t, Prim.charToLower);
    };

    public shared func getSize() : async Nat{
        return Prim.rts_memory_size();
    };

    public shared query ({ caller }) func http_request_streaming_callback(
        st : AssetStorage.StreamingCallbackToken,
    ) : async AssetStorage.StreamingCallbackHttpResponse {
        switch (Trie.find(assets, keyT(st.key), Text.equal)) {
            case (null) throw Error.reject("key not found: " # st.key);
            case (?asset) {
                switch (Trie.find(asset.encodings, keyT(st.content_encoding), Text.equal)) {
                    case (null) throw Error.reject("encoding not found: " # st.content_encoding);
                    case (?encoding) {
                        if (st.sha256 != ?encoding.sha256) {
                            throw Error.reject("SHA-256 mismatch");
                        };
                        {
                            token = _create_token(
                                st.key,
                                st.index,
                                asset,
                                st.content_encoding,
                                encoding,
                            );
                            body = encoding.content_chunks[st.index];
                        };
                    };
                };
            };
        };
    };

    private func _create_token(
        key : Text,
        chunk_index : Nat,
        asset : State.Asset,
        content_encoding : Text,
        encoding : State.AssetEncoding,
    ) : ?AssetStorage.StreamingCallbackToken {
        if (chunk_index + 1 >= encoding.content_chunks.size()) {
            null;
        } else {
            ?{
                key;
                content_encoding;
                index = chunk_index + 1;
                sha256 = ?encoding.sha256;
            };
        };
    };

    public shared query ({ caller }) func list({}) : async [AssetStorage.AssetDetails] {
        let details = Buffer.Buffer<AssetStorage.AssetDetails>(Trie.size(assets));
        for ((key, a) in Trie.iter(assets)) {
            let encodingsBuffer = Buffer.Buffer<AssetStorage.AssetEncodingDetails>(Trie.size(a.encodings));
            for ((n, e) in Trie.iter(a.encodings)) {
                encodingsBuffer.add({
                    content_encoding = n;
                    sha256 = ?e.sha256;
                    length = e.total_length;
                    modified = e.modified;
                });
            };
            let encodings = Array.sort(
                Buffer.toArray(encodingsBuffer),
                func(
                    a : AssetStorage.AssetEncodingDetails,
                    b : AssetStorage.AssetEncodingDetails,
                ) : Order.Order {
                    Text.compare(a.content_encoding, b.content_encoding);
                },
            );
            details.add({
                key;
                content_type = a.content_type;
                encodings;
            });
        };
        Buffer.toArray(details);
    };

    private func _set_asset_content(
        a : AssetStorage.SetAssetContentArguments,
    ) : Result.Result<(), Text> {
        if (a.chunk_ids.size() == 0) return #err("must have at least one chunk");
        switch (Trie.find(assets, keyT(a.key), Text.equal)) {
            case (null) #err("asset not found: " # a.key);
            case (?asset) {
                var content_chunks : Buffer.Buffer<[Nat8]> = Buffer.Buffer<[Nat8]>(0);
                for (chunkID in a.chunk_ids.vals()) {
                    switch (Trie.find(chunks, key(chunkID), Nat32.equal)) {
                        case (null) return #err("chunk not found: " # Nat32.toText(chunkID));
                        case (?chunk) {
                            content_chunks.add(chunk.content);
                        };
                    };
                };
                for (chunkID in a.chunk_ids.vals()) {
                    chunks := Trie.remove(chunks, key(chunkID), Nat32.equal).0;
                };
                var sha256 : [Nat8] = [];
                var total_length = 0;
                for (chunk in content_chunks.vals()) total_length += chunk.size();

                var encodings = asset.encodings;
                encodings := Trie.put(encodings, keyT(a.content_encoding), Text.equal, {
                        modified = Time.now();
                        content_chunks = Buffer.toArray(content_chunks);
                        certified = false;
                        total_length;
                        sha256;
                    }).0;
                assets := Trie.put(assets, keyT(a.key), Text.equal, {
                        content_type = asset.content_type;
                        encodings;
                    }).0;
                #ok();
            };
        };
    };

    //utility functions
    //
    public func commit_asset_upload(batchId : AssetStorage.BatchId, _key : AssetStorage.Key, _type : Text, chunkIds : [AssetStorage.ChunkId], _content_encoding : Text, etag : Text) : async (Result.Result<(), Text>) {
        var res : Result.Result<(), Text> = _create_asset({
            key =  _key;
            content_type = _type;
        });
        switch (res) {
            case (#err _) {
                return #err("check _create_asset");
            };
            case (#ok) {
                var res1 : Result.Result<(), Text> = _set_asset_content({
                    key = _key;
                    sha256 = null;
                    chunk_ids = chunkIds;
                    content_encoding = _content_encoding;
                });
                switch (res1) {
                    case (#err _) {
                        etags := Trie.put(etags, keyT(_key), Text.equal, etag).0;
                        return #err("check _set_asset_content");
                    };
                    case (#ok) {
                        return #ok();
                    };
                };
            };
        };
    };
    
    public shared ({ caller }) func getCaller() : async Principal {
        caller;
    };

    func get_etag(key : Text) : (Text){
        switch(Trie.find(etags, keyT(key), Text.equal)){
            case(?e){
                return e;
            };
            case _ {
                return "not found";
            };
        }
    };

};

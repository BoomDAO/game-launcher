import AssetStorage "AssetStorage";

module Streaming {
    public func forEachDo(
        // For every token in the given streaming strategy...
        strategy : AssetStorage.StreamingStrategy,
        // Do the following...
        f        : (index : Nat, body : [Nat8]) -> (),
    ) : async () {
        let (init, callback) = switch (strategy) {
            case (#Callback(v)) (v.token, v.callback);
        };

        var token = ?init;
        loop {
            switch (token) {
                case (null) { return; };
                case (? tk) {
                    let resp = await callback(tk);
                    f(tk.index, resp.body);
                    token := resp.token;
                };
            };
        };
    };
};

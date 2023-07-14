import TrieMap "mo:base/TrieMap";

module{
    public func containsKey<A, B>(map: TrieMap.TrieMap<A, B>, key: A): Bool {
        switch(map.get(key)){
            case (?a) true;
            case (_) false
        }
    };

    public func putOrUpdate<A, B>(map: TrieMap.TrieMap<A, B>, key: A, defaultVal: B, update: (B) -> B){
        let newVal = switch (map.get(key)){
            case (?val) update(val);
            case (_) defaultVal;
        };

        map.put(key, newVal)
    };
};
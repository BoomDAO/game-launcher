import Text "mo:base/Text";

import Map "../utils/Map";
import TGlobal "./v2.global.types";

module {

    public type Entity = {
        wid : TGlobal.worldId;
        eid : TGlobal.entityId;
        fields : Map.Map<Text, Text>;
    };

    public type StableEntity = {
        wid : TGlobal.worldId;
        eid : TGlobal.entityId;
        fields : [TGlobal.Field];
    };

    public type EntitySchema = {
        uid : Text;
        eid : Text;
        fields : [TGlobal.Field];
    };

    public type Config = {
        cid : TGlobal.configId;
        fields : Map.Map<Text, Text>;
    };

    public type StableConfig = {
        cid : TGlobal.configId;
        fields : [TGlobal.Field];
    };

    public type EntityPermission = {
        wid : TGlobal.worldId;
        eid : TGlobal.entityId;
    };

    public type GlobalPermission = {
        wid : TGlobal.worldId;
    };
};

import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import Utils "../utils/Utils";
import Int "mo:base/Int";

import ENV "../utils/Env";
import TDatabase "../types/world.types";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

module{
    public type entityId = Text;
    public type groupId = Text;
    public type worldId = Text;

    public type attribute = Text;

    public type nodeId = Text;
    // ================ CONFIGS ========================= //

    public type EntityConfig = 
    {
        eid: Text;
        gid: Text;
        name: ?Text;
        description: ?Text;
        imageUrl: ?Text;
        objectUrl: ?Text;
        rarity: ?Text;
        duration: ?Nat;
        tag: Text;
        metadata: Text;
    };

    //ActionResult
    public type quantity = Float;
    public type duration = Nat;
    
    public type MintToken = {
        name: Text;
        description : Text; 
        imageUrl: Text; 
        canister : Text;
    };
    public type MintNft = {
        name: Text;
        description : Text; 
        imageUrl: Text; 
        canister : Text;
        assetId: Text;
        collection:  Text;
        metadata: Text;
    };
    public type ActionOutcomeOption = {
        weight: Float;
        option : {
            #mintToken : MintToken;
            #mintNft : MintNft;
            #setEntityAttribute : (
                entityId,
                groupId,
                worldId,
                attribute
            );
            #spendEntityQuantity : (
                entityId,
                groupId,
                worldId,
                quantity
            );
            #receiveEntityQuantity : (
                entityId,
                groupId,
                worldId,
                quantity
            );
            #renewEntityExpiration : (
                entityId,
                groupId,
                worldId,
                duration
            );
            #reduceEntityExpiration : (
                entityId,
                groupId,
                worldId,
                duration
            );
            #deleteEntity : (
                entityId,
                groupId,
                worldId,
                entityId
            );
        }
    };
    public type ActionOutcome = {
        possibleOutcomes: [ActionOutcomeOption];
    };
    public type ActionResult = {
        outcomes: [ActionOutcome];
    };

    //ActionConfig
    public type ActionArg = 
    {
        #burnNft : {actionId: Text; index: Nat32; aid: Text};
        #spendTokens : {actionId: Text; hash: Nat64; };
        #spendEntities : {actionId: Text; };
        #claimStakingReward : {actionId: Text; };
    };

    public type ActionDataType = 
    {
        #burnNft : {nftCanister: Text;};
        #spendTokens : {tokenCanister: ? Text; amt: Float; baseZeroCount: Nat;  toPrincipal : Text; };
        #spendEntities : {};
        #claimStakingReward : { requiredAmount : Nat; tokenCanister: Text; };
    };
    public type ActionConstraint = 
    {
        #timeConstraint: { intervalDuration: Nat; actionsPerInterval: Nat; };
        #entityConstraint : { worldId: Text; groupId: Text; entityId: Text; equalToAttribute: ?Text; greaterThanOrEqualQuantity: ?Float; lessThanQuantity: ?Float; notExpired: ?Bool};
    };
    public type ActionConfig = 
    {
        aid : Text;
        name : ?Text;
        description : ?Text;
        actionDataType: ActionDataType;
        actionResult: ActionResult;
        actionConstraints: ?[ActionConstraint];
    };

    //ConfigDataType

    public type EntityConfigs = [EntityConfig]; 
    public type ActionConfigs = [ActionConfig]; 
    
    public let entityConfigs : EntityConfigs = [      
        // //ITEMS
        { 
            eid = "pastry_candy_cake"; 
            gid = "";
            name = ?"Thicc Boy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?""; 
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 

        },
        { 
            eid = "pastry_candy_candy";
            gid = "";
            name = ?"The Candy Emperor"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";  
            rarity = ?"common"; 
            duration = null; 
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "pastry_candy_croissant";
            gid = "";
            name = ?"Le Frenchy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "pastry_candy_cupcake"; 
            gid = "";
            name = ?"Princess Sweet Cheeks"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_donut"; 
            gid = "";
            name = ?"Donyatsu"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_ice_cream";
            gid = "";
            name = ?"Prince Yummy Buddy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_marshmallow";
            gid = "";
            name = ?"Sugar Baby"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_chocolate";
            gid = "";
            name = ?"Sir Chocobro"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"special";
            duration = null;
            metadata = "";
            tag = "item skin";
        },

        { 
            eid = "item1";
            gid = "";
            name = ?"Item 1"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "item2";
            gid = "";
            name = ?"Item 2"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        //// add more items here...
    ];
    public let actionConfigs : ActionConfigs = [
        { 
            aid = "burnPastryRewardAction";
            name = ?"Pastry Reward Spin";
            description = ?"You can burn Pastry Reward Nft to get a Pastry Reward!";
            actionDataType = #burnNft { nftCanister = ""; };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity ("game", "pastry_candy_cake", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_candy", "", 1); weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_chocolate", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_croissant", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_cupcake", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_donut", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_ice_cream", "", 1);  weight = 100;},
                            { option = #receiveEntityQuantity ("game", "pastry_candy_marshmallow", "", 1);  weight = 100;},
                        ]
                    }
                ]
            };
            actionConstraints = ? [
                #timeConstraint { intervalDuration = 120_000_000_000; actionsPerInterval = 1; }
            ];
        },
        { 
            aid = "buyItem1_Icp";
            name = ?"Item 1 Offer!";
            description = ?"You get a Item 1 by spending just 0.0001 icp";
            actionDataType =  #spendTokens { tokenCanister =  null; amt = 0.0001; baseZeroCount = 100_000_000; toPrincipal = ENV.paymenthub_canister_id };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity ("game", "item1", "", 1); weight = 100;},
                        ]
                    }
                ]
            };
            actionConstraints = ? [
                #timeConstraint { intervalDuration = 120_000_000_000; actionsPerInterval = 1; }
            ];
        },
        { 
            aid = "buyItem2_Icrc";
            name = ?"Item 2 Offer!";
            description = ?"";
            actionDataType =  #spendTokens { tokenCanister = ? ENV.ICRC1_Ledger; amt = 0.0001; baseZeroCount = 1_000_000_000_000_000_000; toPrincipal = ENV.paymenthub_canister_id };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity ("game", "item2", "", 1); weight = 100;},
                        ]
                    }
                ]
            };
            actionConstraints = ? [
                #timeConstraint { intervalDuration = 120_000_000_000; actionsPerInterval = 1; }
            ];
        },
        { 
            aid = "buyItem2_item1";
            name = ?"Trade Offer";
            description = ?"";
            actionDataType =  #spendEntities {};
            actionResult = { 
                outcomes = [
                    {//Substract
                        possibleOutcomes = [
                            { option = #spendEntityQuantity ("game", "item2","", 1); weight = 100;},
                        ]
                    },
                    {//Add
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity ("game", "item1","", 1); weight = 100;},
                        ]
                    }
                ]
            };
            actionConstraints = ? [
                #timeConstraint { intervalDuration = 120_000_000_000; actionsPerInterval = 1; }
            ];
        },
    ];
}
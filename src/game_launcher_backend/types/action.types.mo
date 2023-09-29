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
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

import TEntity "./entity.types";
import TGlobal "./global.types";

module {

    public type attribute = Text;
    public type quantity = Float;
    public type duration = Nat;

    public type ActionState = {
        actionId : Text;
        intervalStartTs : Nat;
        actionCount : Nat;
    };

    public type ActionArg = {
        #default : { actionId : Text };
        #verifyBurnNfts : { actionId : Text; indexes : [Nat32] };
        #verifyTransferIcp : { actionId : Text; blockIndex : Nat64 };
        #verifyTransferIcrc : { actionId : Text; blockIndex : Nat };
        #claimStakingRewardNft : { actionId : Text };
        #claimStakingRewardIcp : { actionId : Text };
        #claimStakingRewardIcrc : { actionId : Text };
    };

    public type MintToken = {
        quantity : Float;
        canister : Text;
    };
    public type MintNft = {
        index : ?Nat32;
        canister : Text;
        assetId : Text;
        metadata : Text;
    };
    public type DeleteEntity = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
    };
    public type RenewTimestamp = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        field : Text;
        value : Nat;
    };
    public type SetString = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        field : Text;
        value : Text;
    };
    public type SetNumber = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        field : Text;
        value : Float;
    };
    public type DecrementNumber = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        field : Text;
        value : Float;
    };
    public type IncrementNumber = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        field : Text;
        value : Float;
    };
    public type ActionOutcomeOption = {
        weight : Float;
        option : {
            #mintToken : MintToken;
            #mintNft : MintNft;
            #deleteEntity : DeleteEntity;
            #renewTimestamp : RenewTimestamp;
            #setString : SetString;
            #setNumber : SetNumber;
            #decrementNumber : DecrementNumber;
            #incrementNumber : IncrementNumber;
        };
    };
    public type ActionOutcome = {
        possibleOutcomes : [ActionOutcomeOption];
    };
    public type ActionResult = {
        outcomes : [ActionOutcome];
    };

    public type ActionPlugin = {
        #verifyBurnNfts : { canister : Text; requiredNftMetadata : ?[Text] };
        #verifyTransferIcp : { amt : Float; toPrincipal : Text };
        #verifyTransferIcrc : {
            canister : Text;
            amt : Float;
            toPrincipal : Text;
        };
        #claimStakingRewardNft : { canister : Text; requiredAmount : Nat };
        #claimStakingRewardIcp : { requiredAmount : Float };
        #claimStakingRewardIcrc : { canister : Text; requiredAmount : Float };
    };
    public type ActionConstraint = {
        timeConstraint : ?{
            intervalDuration : Nat;
            actionsPerInterval : Nat;
        };
        entityConstraint : ?[{
            wid : ?TGlobal.worldId;
            gid : TGlobal.groupId;
            eid : TGlobal.entityId;
            fieldName : Text;
            validation : {
                #greaterThanNumber : Float;
                #lessThanNumber : Float;
                #greaterThanEqualToNumber : Float;
                #lessThanEqualToNumber : Float;
                #equalToNumber : Float;
                #equalToString : Text;
                #greaterThanNowTimestamp;
                #lessThanNowTimestamp;
            };
        }];
    };
    public type Action = {
        aid : Text;
        name : ?Text;
        description : ?Text;
        imageUrl : ?Text;
        tag : ?Text;
        actionPlugin : ?ActionPlugin;
        actionConstraint : ?ActionConstraint;
        actionResult : ActionResult;
    };

    public type ActionResponse = (ActionState, [TEntity.Entity], [MintNft], [MintToken]);
};

import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import Utils "../utils/Utils";
import Int "mo:base/Int";

import ENV "../utils/Env";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

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

    //EDITED
    public type ActionArg = {
        actionId : Text; 
        targetPrincipalId : ?Text
    };

    //OTHER ACTION OUTCOMES
    public type TransferIcrc = {
        quantity : Float;
        canister : Text;
    };
    public type MintNft = {
        index : ?Nat32;
        canister : Text;
        assetId : Text;
        metadata : Text;
    };
    //ENTITY ACTION OUTCOMES TYPES
    //EDITED
    public type DeleteEntity = {
    };
    //EDITED
    public type RenewTimestamp = {
        field : Text;
        value : { #number : Float; #formula : Text };
    };
    
    //EDITED
    public type SetText = {
        field : Text;
        value : Text;
    };
    //EDITED
    public type SetNumber = {
        field : Text;
        value : { #number : Float; #formula : Text };
    };
    //EDITED
    public type DecrementNumber = {
        field : Text;
        value : { #number : Float; #formula : Text };
    };
    //EDITED
    public type IncrementNumber = {
        field : Text;
        value : { #number : Float; #formula : Text };
    };

    //NEW
    public type ReplaceText = {
        field : Text;
        oldText : Text;
        newText : Text;
    };

    //ENTITY ACTION OUTCOMES
    //NEW
    public type UpdateEntity  = {
        wid : ?TGlobal.worldId;
        gid : TGlobal.groupId;
        eid : TGlobal.entityId;
        updateType : {
            #deleteEntity : DeleteEntity;
            #renewTimestamp : RenewTimestamp;
            #setText : SetText;
            #setNumber : SetNumber;
            #decrementNumber : DecrementNumber;
            #incrementNumber : IncrementNumber;
            #replaceText : ReplaceText;
        };
    };


    //OUTCOMES
    public type ActionOutcomeOption = {
        weight : Float;
        option : {
            #transferIcrc : TransferIcrc;
            #mintNft : MintNft;
            #updateEntity  : UpdateEntity ;
        };
    };
    public type ActionOutcome = {
        possibleOutcomes : [ActionOutcomeOption];
    };
    public type ActionResult = {
        outcomes : [ActionOutcome];
    };

    //CONCSTRAINTS
    //NEW
    public type NftTransfer = { 
        toPrincipal : Text;
    };

    //NEW
    public type NftTx = {
        nftConstraintType : { #hold : { #boomEXT; #originalEXT}; #transfer: NftTransfer };
        canister : Text;
        metadata : ?Text;
    };
    //NEW
    public type IcpTx = {
        amount : Float;
        toPrincipal : Text;
    };
    //NEW
    public type IcrcTx = {
        amount : Float;
        toPrincipal : Text;
        canister : Text;
    };

    public type EntityConstraint = {
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
            #equalToText : Text;
            #greaterThanNowTimestamp;
            #lessThanNowTimestamp;
            #containsText : Text;
        };
    };

    //EDITED
    public type ActionConstraint = {
        timeConstraint : ?{
            intervalDuration : Nat;
            actionsPerInterval : Nat;
        };
        entityConstraint : [EntityConstraint];
        icpConstraint: ? IcpTx;
        icrcConstraint: [IcrcTx];
        nftConstraint: [NftTx];
    };

    //ACTIONS
    //NEW
    public type SubAction =
    {
        actionConstraint : ?ActionConstraint;
        actionResult : ActionResult;
    };

    //EDITED
    public type Action = {
        aid : Text;
        callerAction : ?SubAction;
        targetAction : ?SubAction;
        name : ?Text;
        description : ?Text;
        imageUrl : ?Text;
        tag : ?Text;
    };

    public type ActionReturn =
    {
        callerOutcomes : ? [ActionOutcomeOption];
        targetOutcomes : ? [ActionOutcomeOption];
    };
};

import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

import TEntity "./v1.entity.types";
import TGlobal "./v1.global.types";
import TConstraints "./v1.constraints.types";

module {

    public type attribute = Text;
    public type quantity = Float;
    public type duration = Nat;

    public type ActionState = {
        actionId : Text;
        intervalStartTs : Nat;
        actionCount : Nat;
    };

    public type ActionLockStateArgs = {
        uid : Text;
        aid : Text;
    };

    public type ActionArg = {
        actionId : Text; 
        fields : [TGlobal.Field];
    };

    //OTHER ACTION OUTCOMES
    public type TransferIcrc = {
        quantity : Float;
        canister : Text;
    };
    public type MintNft = {
        canister : Text;
        assetId : Text;
        metadata : Text;
    };
    //ENTITY ACTION OUTCOMES TYPES
    public type DeleteEntity = {
    };
    public type DeleteField = {
        fieldName : Text;
    };
    public type RenewTimestamp = {
        fieldName : Text;
        fieldValue : { #number : Float; #formula : Text };
    };
    
    public type SetText = {
        fieldName : Text;
        fieldValue : Text;
    };
    public type AddToList = {
        fieldName : Text;
        value : Text;
    };
    public type RemoveFromList = {
        fieldName : Text;
        value : Text;
    };

    public type SetNumber = {
        fieldName : Text;
        fieldValue : { #number : Float; #formula : Text };
    };
    public type DecrementNumber = {
        fieldName : Text;
        fieldValue : { #number : Float; #formula : Text };
    };
    public type IncrementNumber = {
        fieldName : Text;
        fieldValue : { #number : Float; #formula : Text };
    };

    public type UpdateEntityType = {
        #deleteEntity : DeleteEntity;
        #renewTimestamp : RenewTimestamp;
        #setText : SetText;
        #setNumber : SetNumber;
        #decrementNumber : DecrementNumber;
        #incrementNumber : IncrementNumber;
        #addToList : AddToList;
        #removeFromList : RemoveFromList;
        #deleteField : DeleteField
    };

    //ENTITY ACTION OUTCOMES
    public type UpdateEntity  = {
        wid : ?TGlobal.worldId;
        eid : TGlobal.entityId;
        updates : [UpdateEntityType];
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

    public type ActionConstraint = {
        timeConstraint : ?{
            actionTimeInterval : ? {
                intervalDuration : Nat;
                actionsPerInterval : Nat;
            };
            actionExpirationTimestamp : ?Nat;
        };
        entityConstraint : [TConstraints.EntityConstraint];
        icrcConstraint: [TConstraints.IcrcTx];
        nftConstraint: [TConstraints.NftTx];
    };

    //ACTIONS
    public type SubAction =
    {
        actionConstraint : ?ActionConstraint;
        actionResult : ActionResult;
    };

    public type Action = {
        aid : Text;
        callerAction : ?SubAction;
        targetAction : ?SubAction;
        worldAction : ?SubAction;
    };

    public type ActionReturn =
    {
        callerPrincipalId : Text;
        targetPrincipalId : ? Text;
        worldPrincipalId : Text;
        callerOutcomes : ? [ActionOutcomeOption];
        targetOutcomes : ? [ActionOutcomeOption];
        worldOutcomes : ? [ActionOutcomeOption];
    };
};

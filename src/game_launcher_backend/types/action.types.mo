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
import TConstraints "./constraints.types";

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
    public type DeleteEntity = {};
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

    public type DecrementActionCount = {
        value : { #number : Float; #formula : Text };
    };

    public type UpdateActionType = {
        #decrementActionCount : DecrementActionCount;
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
        #deleteField : DeleteField;
    };

    //ENTITY ACTION OUTCOMES
    public type UpdateEntity = {
        wid : ?TGlobal.worldId;
        eid : TGlobal.entityId;
        updates : [UpdateEntityType];
    };

    public type UpdateAction = {
        aid : TGlobal.actionId;
        updates : [UpdateActionType];
    };

    //OUTCOMES
    public type ActionOutcomeHistory = {
        wid : TGlobal.worldId;
        option : {
            #transferIcrc : TransferIcrc;
            #mintNft : MintNft;
            #updateEntity : UpdateEntity;
            #updateAction : UpdateAction;
        };
        appliedAt : Nat;
    };
    public type ActionOutcomeOption = {
        weight : Float;
        option : {
            #transferIcrc : TransferIcrc;
            #mintNft : MintNft;
            #updateEntity : UpdateEntity;
            #updateAction : UpdateAction;
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
            actionTimeInterval : ?{
                intervalDuration : Nat;
                actionsPerInterval : Nat;
            };
            actionStartTimestamp : ?Nat;
            actionExpirationTimestamp : ?Nat;
            actionHistory : [{
                #transferIcrc : TransferIcrc;
                #mintNft : MintNft;
                #updateEntity : UpdateEntity;
                #updateAction : UpdateAction;
            }];
        };
        entityConstraint : [TConstraints.EntityConstraint];
        icrcConstraint : [TConstraints.IcrcTx];
        nftConstraint : [TConstraints.NftTx];
    };

    //ACTIONS
    public type SubAction = {
        actionConstraint : ?ActionConstraint;
        actionResult : ActionResult;
    };

    public type Action = {
        aid : Text;
        callerAction : ?SubAction;
        targetAction : ?SubAction;
        worldAction : ?SubAction;
    };

    public type ActionReturn = {
        callerPrincipalId : Text;
        targetPrincipalId : Text;
        worldPrincipalId : Text;
        callerOutcomes : [ActionOutcomeOption];
        targetOutcomes : [ActionOutcomeOption];
        worldOutcomes : [ActionOutcomeOption];
    };

    public type ConstraintStatus = {
        eid : Text;
        fieldName: Text;
        currentValue: Text;
        expectedValue: Text;
    };
    public type ActionStatusReturn = {
        isValid: Bool;
        timeStatus : {
            nextAvailableTimestamp : ?Nat;
            actionsLeft : ?Nat;
        };
        actionHistoryStatus : [ConstraintStatus];
        entitiesStatus : [ConstraintStatus];
    };
};

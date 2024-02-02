import TGlobal "./global.types";

module{
    //CONCSTRAINTS

    public type NftTransfer = { 
        toPrincipal : Text;
    };
    public type NftTx = {
        nftConstraintType : { #hold : { #boomEXT; #originalEXT}; #transfer: NftTransfer };
        canister : Text;
        metadata : ?Text;
    };

    public type IcrcTx = {
        amount : Float;
        toPrincipal : Text;
        canister : Text;
    };

    public type ContainsText = {
        fieldName : Text;
        value : Text;
        contains : Bool;
    };
    public type EqualToText = {
        fieldName : Text;
        value : Text;
        equal : Bool;
    };
    public type EqualToNumber = {
        fieldName : Text;
        value : Float;
        equal : Bool;
    };
    public type GreaterThanNumber = {
        fieldName : Text;
        value : Float;
    };
    public type LessThanNumber = {
        fieldName : Text;
        value : Float;
    };
    public type GreaterThanOrEqualToNumber = {
        fieldName : Text;
        value : Float;
    };
    public type LowerThanOrEqualToNumber = {
        fieldName : Text;
        value : Float;
    };
    public type GreaterThanNowTimestamp = {
        fieldName : Text;
    };
    public type LessThanNowTimestamp = {
        fieldName : Text;
    };

    public type ExistField = {
        fieldName : Text;
        value : Bool;
    };

    public type Exist = {
        value : Bool;
    };

    public type EntityConstraintType = {
        #greaterThanNumber : GreaterThanNumber;
        #lessThanNumber : LessThanNumber;
        #greaterThanEqualToNumber : GreaterThanOrEqualToNumber;
        #lessThanEqualToNumber : LowerThanOrEqualToNumber;
        #equalToNumber : EqualToNumber;
        #equalToText : EqualToText;
        #greaterThanNowTimestamp : GreaterThanNowTimestamp;
        #lessThanNowTimestamp : LessThanNowTimestamp;
        #containsText : ContainsText;
        #existField : ExistField;
        #exist : Exist;
    };

    public type EntityConstraint = {
        wid : ?TGlobal.worldId;
        eid : TGlobal.entityId;
        entityConstraintType : EntityConstraintType;
    };
}
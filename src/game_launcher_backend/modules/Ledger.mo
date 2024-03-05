import ICP "../types/icp.types";
import ICRC1 "../types/icrc.types";
import EXTCORE "../utils/Core";

module {
    //IC Ledger Canister Interface
    public type ICP = ICP.Self;

    //ICRC-1 Ledger Canister Interface
    public type ICRC1 = ICRC1.Self;

    //EXT V2 Canister Interface
    public type EXT = actor {
        getRegistry : shared query () -> async ([(Nat32, Text)]); 
        transfer : shared (EXTCORE.TransferRequest) -> async (EXTCORE.TransferResponse);
    };
};
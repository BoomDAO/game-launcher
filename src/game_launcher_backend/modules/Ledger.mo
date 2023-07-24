import ICP "../utils/icp.types";
import ICRC1 "../utils/icrc.types";
import EXTCORE "../utils/Core";

module {
    //IC Ledger Canister Interface
    public type ICP = actor {
        account_balance : shared query ICP.AccountBalanceArgs -> async ICP.Tokens;
        archives : shared query () -> async ICP.Archives;
        decimals : shared query () -> async { decimals : Nat32 };
        name : shared query () -> async { name : Text };
        query_blocks : shared query ICP.GetBlocksArgs -> async ICP.QueryBlocksResponse;
        symbol : shared query () -> async { symbol : Text };
        transfer : shared ICP.TransferArgs -> async ICP.TransferResult;
        transfer_fee : shared query ICP.TransferFeeArg -> async ICP.TransferFee;
    };

    //ICRC-1 Ledger Canister Interface
    public type ICRC1 = actor {
        get_transactions : shared query (ICRC1.GetTransactionsRequest) -> async (ICRC1.GetTransactionsResponse);
        icrc1_transfer : (ICRC1.TransferArg) -> async (ICRC1.Result);
    };

    //EXT V2 Canister Interface
    public type EXT = actor {
        getRegistry : shared query () -> async ([(Nat32, Text)]); 
        transfer : shared (EXTCORE.TransferRequest) -> async (EXTCORE.TransferResponse);
    };
};
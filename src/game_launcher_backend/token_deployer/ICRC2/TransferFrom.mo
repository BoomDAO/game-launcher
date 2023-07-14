import Option "mo:base/Option";
import Result "mo:base/Result";

import T "Types";
import Utils "Utils";
import Approve "Approve";
import Transfer "../ICRC1/Transfer";

module {
    /// Checks if a Transfer From request is valid
    public func validate_request(
        token : T.TokenData,
        txf_req : T.TransactionFromRequest,
    ) : Result.Result<(), T.TransferFromError> {

        let { allowance; expires_at } = Utils.get_allowance(token.approvals, txf_req.encoded);
        if (allowance < txf_req.amount + Option.get(txf_req.fee, token._fee)) {
            return #err(
                #InsufficientAllowance({
                    allowance = allowance;
                })
            );
        };
        if (not Approve.validate_expiration(token, expires_at)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Allowance has already expired";
                })
            );
        };

        switch (Transfer.validate_request(token, txf_req)) {
            case (#err(errorType)) {
                return #err(errorType);
            };
            case (#ok(_)) {};
        };

        return #ok();
    };
};

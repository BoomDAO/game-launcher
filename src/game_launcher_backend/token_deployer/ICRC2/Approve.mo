import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Time "mo:base/Time";

import STMap "../../utils/StableTrieMap";


import T "Types";
import Utils "Utils";
import Account "../ICRC1/Account";
import Transfer "../ICRC1/Transfer";

module {

    // Checks if an approval expiration is greater than the current ledger time
    public func validate_expiration(token : T.TokenData, expires_at : ?Nat64) : Bool {
        switch (expires_at) {
            case null { return true };
            case (?expiration) {
                return Transfer.is_in_future(token, expiration);
            };
        };
    };

    /// Checks if an approve request is valid
    public func validate_request(
        token : T.TokenData,
        app_req : T.ApproveRequest,
    ) : Result.Result<(), T.ApproveError> {

        if (app_req.from.owner == app_req.spender.owner) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "The spender account owner cannot be equal to the source account owner.";
                })
            );
        };

        if (not Account.validate(app_req.from)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for approval source. " # debug_show (app_req.from);
                })
            );
        };

        if (not Account.validate(app_req.spender)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for approval spender. " # debug_show (app_req.spender);
                })
            );
        };

        // TODO: Verify if approval memo should be validated for approvals.
        if (not Transfer.validate_memo(app_req.memo)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Memo must not be more than 32 bytes";
                })
            );
        };

        // TODO: Verify if approval fee should be validated as a transfer fee.
        if (not Transfer.validate_fee(token, app_req.fee)) {
            return #err(
                #BadFee {
                    expected_fee = token._fee;
                }
            );
        };

        let balance : T.Balance = Utils.get_balance(
            token.accounts,
            app_req.encoded.from,
        );

        // If no approval fee provided, validates against transaction fee.
        if(Option.get(app_req.fee, token._fee) > balance){
            return #err(#InsufficientFunds { balance });
        };

        // Validates that the approval contains the expected allowance
        switch (app_req.expected_allowance) {
            case null {};
            case (?expected) {
                let allowance_record = Utils.get_allowance(token.approvals, app_req.encoded);
                if (expected != allowance_record.allowance) {
                    return #err(
                        #AllowanceChanged {
                            current_allowance = allowance_record.allowance;
                        }
                    );
                };
            };
        };

        if (not validate_expiration(token, app_req.expires_at)) {
            return #err(
                #Expired {
                    ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                }
            );
        };

        switch (app_req.created_at_time) {
            case (null) {};
            case (?created_at_time) {

                if (Transfer.is_too_old(token, created_at_time)) {
                    return #err(#TooOld);
                };

                if (Transfer.is_in_future(token, created_at_time)) {
                    return #err(
                        #CreatedInFuture {
                            ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                        }
                    );
                };
            };
        };

        #ok();
    };

    /// Writes/overwrites the allowance of an approval
    public func write_approval(
        token : T.TokenData,
        app_req : T.WriteApproveRequest,
    ) : async* T.ApproveResult {

        let { amount = allowance; expires_at; encoded } = app_req;
        let prev_allowance = Utils.get_allowance(token.approvals, encoded);
        let new_allowance : T.Allowance = { allowance; expires_at };

        if (new_allowance != prev_allowance) {
            let accont_approvals = Utils.get_account_approvals(token.approvals, encoded.from);
            switch (accont_approvals) {
                case (?approvals) {
                    let spenders = STMap.get(approvals, Blob.equal, Blob.hash, encoded.spender);
                    STMap.put(approvals, Blob.equal, Blob.hash, encoded.spender, new_allowance);
                };
                case null {
                    let approvals : T.Approvals = STMap.new();
                    STMap.put(approvals, Blob.equal, Blob.hash, encoded.spender, new_allowance);
                    STMap.put(token.approvals, Blob.equal, Blob.hash, encoded.from, approvals);
                };
            };
        };

        #Ok(allowance);
    };
};

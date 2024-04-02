import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Char "mo:base/Char";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";

import ICP "icp.types";
import ICRC "icrc.types";

module {

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type AccountIdentifier = Text;

    public type TokenInfo = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        fee: Nat;
        init_total_supply: Nat64;
        token_canister_id: Text;
    };

    public type Token = {
        name: Text;
        logo: Text;
        description: Text;
        symbol: Text;
        decimals: ?Nat8;
        fee: Nat;
        token_canister_id: Text;
    };

    public type SupplyConfigs = {
        gaming_guilds: {
            account: Account;
            icp: Nat64;
            icrc: Nat;
            icp_result: ?ICP.Icrc1TransferResult;
            icrc_result: ?ICRC.TransferResult;
        };
        participants: {
            icrc: Nat;
        };
        team: {
            account: Account;
            icp: Nat64;
            icrc: Nat;
            icp_result: ?ICP.Icrc1TransferResult;
            icrc_result: ?ICRC.TransferResult;
        };
        boom_dao: {
            icp_account: AccountIdentifier;
            icrc_account: Account;
            icp: Nat64;
            icrc: Nat;
            icp_result: ?ICP.TransferResult;
            icrc_result: ?ICRC.TransferResult;
        };
        liquidity_pool: {
            account: Account;
            icp: Nat64;
            icrc: Nat;
            icp_result: ?ICP.Icrc1TransferResult;
            icrc_result: ?ICRC.TransferResult;
        };
    };

    public type TokenSwapConfigs = {
        token_supply_configs: SupplyConfigs;
        min_icp_e8s: Nat64;
        max_icp_e8s: Nat64;
        min_participant_icp_e8s: Nat64;
        max_participant_icp_e8s: Nat64;
        swap_start_timestamp_seconds: Int;
        swap_due_timestamp_seconds: Int;
    };

    public type TokenSwapStatus = {
        running: Bool;
        is_successfull: ?Bool;
    };

    public type ParticipantDetails = {
        account: Account;
        icp_e8s: Nat64;
        token_e8s: ?Nat;           
        refund_result: ?ICP.Icrc1TransferResult;
        mint_result: ?ICRC.TransferResult;
    };
}
import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import Error "mo:base/Error";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import L "mo:base/List";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";
import Random "mo:base/Random";
import Result "mo:base/Result";

import Utils "../utils/Utils";
import Constants "../utils/Env";
import TGlobal "../types/global.types";
import TEntity "../types/entity.types";
import TAction "../types/action.types";

actor Verifier {

  private stable var auth_header : Text = "";
  private stable var idempotent_key : Nat = 0;
  private stable var _emails : Trie.Trie<Text, Text> = Trie.empty(); // email -> otp

  type TransformType = {
    #function : shared CanisterHttpResponsePayload -> async CanisterHttpResponsePayload;
  };

  type TransformArgs = {
    response : CanisterHttpResponsePayload;
    context : Blob;
  };

  type TransformContext = {
    function : shared query TransformArgs -> async CanisterHttpResponsePayload;
    context : Blob;
  };
  type HttpMethod = {
    #get;
    #post;
    #head;
  };
  type HttpHeader = {
    name : Text;
    value : Text;
  };
  type CanisterHttpRequestArgs = {
    url : Text;
    max_response_bytes : ?Nat64;
    headers : [HttpHeader];
    body : [Nat8];
    method : HttpMethod;
    transform : ?TransformContext;
  };

  type CanisterHttpResponsePayload = {
    status : Nat;
    headers : [HttpHeader];
    body : [Nat8];
  };

  type Response = {
    #Success : Text;
    #Err : Text;
  };

  let IC = actor (Constants.IC_Management) : actor {
    http_request : shared CanisterHttpRequestArgs -> async CanisterHttpResponsePayload;
  };

  private func generateOTP_() : async (Text) {
    let seed : Blob = await Random.blob();
    let rand : Nat = Random.rangeFrom(32, seed);
    let size : Nat = Text.size(Nat.toText(rand));
    var number : Text = "";
    var x : Nat = 6;
    if (size < x) {
      var x = 0;
      var y : Nat = x - size;
      number := Nat.toText(rand);
      while (x < y) {
        number := number # "0";
        x := x +1;
      };
    } else if (size > x) {
      label l for (i in Text.toIter(Nat.toText(rand))) {
        number := number #Char.toText(i);
        if (Text.size(number) == x) {
          break l;
        };
      };
    } else {
      number := Nat.toText(rand);
    };
    return number;
  };

  public query func transform(raw : TransformArgs) : async CanisterHttpResponsePayload {
    let transformed : CanisterHttpResponsePayload = {
      status = 200;
      body = [];
      headers = [];
    };
    transformed;
  };

  private func ping_server_to_email(arg : { email : Text; otp : Text }) : async (CanisterHttpResponsePayload) {
    let MAX_RESPONSE_BYTES : Nat64 = 1000;
    let transform_context : TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    var request_headers : [HttpHeader] = [
      { name = "authorization"; value = auth_header },
      { name = "x-idempotence-key"; value = Nat.toText(idempotent_key) },
      { name = "email"; value = arg.email },
      { name = "otp"; value = arg.otp },
    ];
    var req_body : Text = "";
    var request_body : [Nat8] = Blob.toArray(Text.encodeUtf8(req_body));

    let request : CanisterHttpRequestArgs = {
      url = "https://lovely-beignet-bb36a2.netlify.app/.netlify/functions/server/verify";
      max_response_bytes = ?MAX_RESPONSE_BYTES;
      headers = request_headers;
      body = request_body;
      method = #post;
      transform = ?transform_context;
    };
    Cycles.add(100_000_000);
    var res : CanisterHttpResponsePayload = await IC.http_request(request);
    return res;
  };

  public shared ({ caller }) func generateOTP(email : Text) : async Result.Result<Text, Text> {
    assert (caller == Principal.fromActor(Verifier));
    let ?found = Trie.find(_emails, Utils.keyT(email), Text.equal) else return #err("email not valid");
    var otp : Text = await generateOTP_();
    _emails := Trie.put(_emails, Utils.keyT(email), Text.equal, otp).0;
    return #ok(otp);
  };

  public shared ({ caller }) func sendVerificationEmail(_email : Text) : async (Result.Result<Text, Text>) {
    // assert (caller != Principal.fromText("2vxsx-fae"));
    switch (await generateOTP(_email)) {
      case (#ok _otp) {
        idempotent_key := idempotent_key + 1;
        let res = await ping_server_to_email({ email = _email; otp = _otp });
        return #ok("");
      };
      case (#err e) {
        return #err(e);
      };
    };
  };

  public shared ({ caller }) func verifyOTP(arg : { email : Text; otp : Text }) : async (Result.Result<Text, Text>) {
    switch (Trie.find(_emails, Utils.keyT(arg.email), Text.equal)) {
      case (?otp) {
        if (arg.otp == otp) {
          _emails := Trie.remove(_emails, Utils.keyT(arg.email), Text.equal).0;
          let gaming_guild_canister = actor ("6ehny-oaaaa-aaaal-qclyq-cai") : actor {
            processAction : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
          };
          let res = await gaming_guild_canister.processAction({
            actionId = "grant_og_badge";
            fields = [{
              fieldName = "targetPrincipalId";
              fieldValue = Principal.toText(caller);
            }];
          });
          return #ok("");
        } else {
          return #err("OTP not valid");
        };
      };
      case _ {
        return #err("email not valid");
      };
    };
  };

  public query func getTotalEmails() : async Nat {
    return Trie.size(_emails);
  };

  public shared ({caller}) func uploadEmails(comma_separated_emails : Text) : async () {
    assert(caller == Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"));
    let emails = Iter.toArray(Text.tokens(comma_separated_emails, #text(",")));
    for(email in emails.vals()) {
      _emails := Trie.put(_emails, Utils.keyT(email), Text.equal, "").0;
    };
  };

  public query func getAllEmails() : async ([Text]) {
    var b = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_emails)) {
      b.add(i);
    };
    return Buffer.toArray(b);
  };

  public func cleanUp() : async () {
    _emails := Trie.empty();
    idempotent_key := 0;
  };

};

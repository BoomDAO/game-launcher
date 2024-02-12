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
import Proxy "proxyCanister";

actor Verifier {

  private stable var twilioProps = {
    auth : Text = "";
    sid : Text = "";
    from : Text = "";
  };
  private stable var _emails : Trie.Trie<Text, (Text, Bool)> = Trie.empty(); // email -> (otp, status)
  private stable var _phones: Trie.Trie<Text, (Text, Bool)> = Trie.empty(); // phone -> (otp, status)

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

  let ProxyCanister : Proxy.Proxy = actor (Constants.ProxyCanisterId);

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

  public shared({caller}) func setTwilioProps(arg : { auth : Text; sid : Text; from : Text; }) : async () {
    assert(caller == Principal.fromText(Constants.devPrincipalId));
    twilioProps := arg;
    return ();
  };

  public shared({caller}) func ping_server_to_email(arg : { email : Text; otp : Text }) : async (Proxy.HttpRequestEndpointResult) {
    assert (caller == Principal.fromActor(Verifier));
    var request_headers : [HttpHeader] = [
      { name = "authorization"; value = twilioProps.auth },
      { name = "email"; value = arg.email },
      { name = "otp"; value = arg.otp },
    ];
    var req_body : Text = "";
    var request_body : [Nat8] = Blob.toArray(Text.encodeUtf8(req_body));
    let response = await ProxyCanister.http_request({
      request = {
        url = "https://lovely-beignet-bb36a2.netlify.app/.netlify/functions/server/verify";
        method = #POST;
        body = ?Text.encodeUtf8(req_body);
        headers = request_headers;
      };
      timeout_ms = null;
      callback_method_name = null;
    });
    return response;
  };

  public shared({caller}) func ping_server_to_sms(arg : { phone : Text; otp : Text }) : async (Proxy.HttpRequestEndpointResult) {
    assert (caller == Principal.fromActor(Verifier));
    let _url : Text = "https://api.twilio.com/2010-04-01/Accounts/" #twilioProps.sid #"/Messages.json";

    var request_headers : [HttpHeader] = [
      { name = "content-type"; value = "application/x-www-form-urlencoded" },
      { name = "authorization"; value = twilioProps.auth },
      { name = "phone"; value = arg.phone },
      { name = "otp"; value = arg.otp },
    ];

    var req_body = "To=" #arg.phone #"&From=" #twilioProps.from #"&Body=Your BOOM DAO verification code is " #arg.otp #". Do not share this with anyone.";
    var request_body : [Nat8] = Blob.toArray(Text.encodeUtf8(req_body));
    let response = await ProxyCanister.http_request({
      request = {
        url = _url;
        method = #POST;
        body = ?Text.encodeUtf8(req_body);
        headers = request_headers;
      };
      timeout_ms = null;
      callback_method_name = null;
    });
    return response;
  };

  public shared ({ caller }) func generateOTP(email : Text) : async Result.Result<Text, Text> {
    assert (caller == Principal.fromActor(Verifier));
    let ?found = Trie.find(_emails, Utils.keyT(email), Text.equal) else return #err("Email not valid or not registered in OG members list.");
    if(found.1) {
      return #err("This email is already verified. Try different email.");
    };
    var otp : Text = await generateOTP_();
    _emails := Trie.put(_emails, Utils.keyT(email), Text.equal, (otp, false)).0;
    return #ok(otp);
  };

  public shared ({ caller }) func generateSmsOTP(phone : Text) : async Result.Result<Text, Text> {
    assert (caller == Principal.fromActor(Verifier));
    switch (Trie.find(_phones, Utils.keyT(phone), Text.equal)) {
      case (?found) {
        if(found.1) {
          return #err("This phone number is already verified. Try different phone number.");
        }
      };
      case _{};
    };
    var otp : Text = await generateOTP_();
    _phones := Trie.put(_phones, Utils.keyT(phone), Text.equal, (otp, false)).0;
    return #ok(otp);
  };

  public shared ({ caller }) func sendVerificationEmail(_email : Text) : async (Result.Result<Text, Text>) {
    assert (caller != Principal.fromText(Constants.anonPrincipalId));
    switch (await generateOTP(_email)) {
      case (#ok _otp) {
        let res = await ping_server_to_email({ email = _email; otp = _otp });
        return #ok("");
      };
      case (#err e) {
        return #err(e);
      };
    };
  };

  public shared ({ caller }) func sendVerificationSMS(_phone : Text) : async (Result.Result<Text, Text>) {
    assert (caller != Principal.fromText(Constants.anonPrincipalId));
    switch (await generateSmsOTP(_phone)) {
      case (#ok _otp) {
        let res = await ping_server_to_sms({ phone = _phone; otp = _otp });
        return #ok("");
      };
      case (#err e) {
        return #err(e);
      };
    };
  };

  public shared ({ caller }) func verifyOTP(arg : { email : Text; otp : Text }) : async (Result.Result<Text, Text>) {
    switch (Trie.find(_emails, Utils.keyT(arg.email), Text.equal)) {
      case (?(otp, status)) {
        if (arg.otp == otp and status == false) {
          let gaming_guild_canister = actor (Constants.GamingGuildsCanisterId) : actor {
            processAction : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
          };
          let res = await gaming_guild_canister.processAction({
            actionId = "grant_og_badge";
            fields = [{
              fieldName = "target_principal_id";
              fieldValue = Principal.toText(caller);
            }];
          });
          switch (res){
            case (#ok o) {
              _emails := Trie.put(_emails, Utils.keyT(arg.email), Text.equal, (otp, true)).0;
              return #ok("");
            };
            case (#err e) {
              return #err(e);
            };
          };
        } else {
          return #err("OTP not valid or email already verified.");
        };
      };
      case _ {
        return #err("This email not valid, try different email.");
      };
    };
  };

  public shared ({ caller }) func verifySmsOTP(arg : { phone : Text; otp : Text }) : async (Result.Result<Text, Text>) {
    switch (Trie.find(_phones, Utils.keyT(arg.phone), Text.equal)) {
      case (?(otp, status)) {
        if (arg.otp == otp and status == false) {
          let gaming_guild_canister = actor (Constants.GamingGuildsCanisterId) : actor {
            processAction : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
          };
          let res = await gaming_guild_canister.processAction({
            actionId = "grant_phone_badge";
            fields = [{
              fieldName = "target_principal_id";
              fieldValue = Principal.toText(caller);
            }];
          });
          switch (res) {
            case (#ok o) {
              _phones := Trie.put(_phones, Utils.keyT(arg.phone), Text.equal, (otp, true)).0;
              return #ok("");
            };
            case (#err e) {
              return #err(e);
            };
          };
          return #ok("");
        } else {
          return #err("OTP not valid or phone number already verified.");
        };
      };
      case _ {
        return #err("Phone number not valid, try different phone number.");
      };
    };
  };

  public query func getTotalEmails() : async Nat {
    return Trie.size(_emails);
  };

  public query func getTotalPhones() : async Nat {
    return Trie.size(_phones);
  };

  public shared ({caller}) func uploadEmails(comma_separated_emails : Text) : async () {
    assert(caller == Principal.fromText(Constants.devPrincipalId));
    let emails = Iter.toArray(Text.tokens(comma_separated_emails, #text(",")));
    for(email in emails.vals()) {
      _emails := Trie.put(_emails, Utils.keyT(email), Text.equal, ("", false)).0;
    };
  };

  public query func getAllEmails() : async ([Text]) {
    var b = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_emails)) {
      b.add(i);
    };
    return Buffer.toArray(b);
  };

  public shared({caller}) func cleanUp() : async () {
    assert(caller == Principal.fromText(Constants.devPrincipalId));
    _emails := Trie.empty();
    _phones := Trie.empty();
  };

};

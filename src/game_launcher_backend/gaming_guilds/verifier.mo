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

  private stable var twilioProps = {
    auth : Text = "";
    sid : Text = "";
    from : Text = "";
  };
  private stable var _emails : Trie.Trie<Text, (Text, Bool)> = Trie.empty(); // email -> (otp, status)
  private stable var _phones : Trie.Trie<Text, (Text, Bool)> = Trie.empty(); // phone -> (otp, status)
  private stable var _idempotency_key : Nat = 0;
  private stable var _auth_key : Text = "";
  private func VerifierId() : Principal = Principal.fromActor(Verifier);

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
  type Token = {
    arbitrary_data : Text;
  };
  type CallbackStrategy = {
    callback : shared query (Token) -> async StreamingCallbackHttpResponse;
    token : Token;
  };
  type StreamingCallbackHttpResponse = {
    body : Blob;
    token : ?Token;
  };
  type StreamingStrategy = {
    #Callback : CallbackStrategy;
  };
  type HeaderField = (Text, Text);
  type HttpResponse = {
    status_code : Nat16;
    headers : [HeaderField];
    body : Blob;
    streaming_strategy : ?StreamingStrategy;
    upgrade : ?Bool;
  };
  type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
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

  public shared ({ caller }) func getPhoneStatus(p : Text) : async ((Text, Bool)) {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    let ?number = Trie.find(_phones, Utils.keyT(p), Text.equal) else return (("", false));
    return number;
  };

  public shared ({ caller }) func setTwilioProps(arg : { auth : Text; sid : Text; from : Text }) : async () {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    twilioProps := arg;
    return ();
  };

  public shared ({ caller }) func getTwilioAuth() : async ({
    auth : Text;
    sid : Text;
    from : Text;
  }) {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    twilioProps;
  };

  public query func transform(raw : TransformArgs) : async CanisterHttpResponsePayload {
    let transformed : CanisterHttpResponsePayload = {
      status = 200;
      body = [];
      headers = [];
    };
    transformed;
  };

  public shared ({ caller }) func ping_server_to_email_courier(arg : { email : Text; otp : Text }) : async (CanisterHttpResponsePayload) {
    assert (caller == Principal.fromActor(Verifier));
    let MAX_RESPONSE_BYTES : Nat64 = 1000;
    let transform_context : TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };
    var request_headers : [HttpHeader] = [
      { name = "authorization"; value = twilioProps.auth },
      { name = "email"; value = arg.email },
      { name = "otp"; value = arg.otp },
      { name = "x-idempotency-key"; value = Nat.toText(_idempotency_key) },
    ];
    var req_body : Text = "";
    var request_body : [Nat8] = Blob.toArray(Text.encodeUtf8(req_body));
    let request : CanisterHttpRequestArgs = {
      url = "https://lovely-beignet-bb36a2.netlify.app/.netlify/functions/server/verify-email-courier";
      max_response_bytes = ?MAX_RESPONSE_BYTES;
      headers = request_headers;
      body = request_body;
      method = #post;
      transform = ?transform_context;
    };
    Cycles.add(100_000_000);
    var response : CanisterHttpResponsePayload = await IC.http_request(request);
    _idempotency_key := _idempotency_key + 1;
    return response;
  };

  public shared ({ caller }) func ping_server_to_sms(arg : { phone : Text; otp : Text }) : async (CanisterHttpResponsePayload) {
    assert (caller == Principal.fromActor(Verifier));
    let MAX_RESPONSE_BYTES : Nat64 = 1000;
    let transform_context : TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };
    let _url : Text = "https://lovely-beignet-bb36a2.netlify.app/.netlify/functions/server/verify-phone-courier";

    var request_headers : [HttpHeader] = [
      { name = "phone"; value = arg.phone },
      { name = "otp"; value = arg.otp },
      { name = "x-idempotency-key"; value = Nat.toText(_idempotency_key) },
      { name = "authorization"; value = twilioProps.auth },
    ];

    var req_body = "";
    var request_body : [Nat8] = Blob.toArray(Text.encodeUtf8(req_body));
    let request : CanisterHttpRequestArgs = {
      url = _url;
      max_response_bytes = ?MAX_RESPONSE_BYTES;
      headers = request_headers;
      body = request_body;
      method = #post;
      transform = ?transform_context;
    };
    Cycles.add(100_000_000);
    var response : CanisterHttpResponsePayload = await IC.http_request(request);
    _idempotency_key := _idempotency_key + 1;
    return response;
  };

  public shared ({ caller }) func generateOTP(email : Text) : async Result.Result<Text, Text> {
    assert (caller == Principal.fromActor(Verifier));
    let ?found = Trie.find(_emails, Utils.keyT(email), Text.equal) else return #err("Email not valid or not registered in OG members list.");
    if (found.1) {
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
        if (found.1) {
          return #err("This phone number is already verified. Try different phone number.");
        };
      };
      case _ {};
    };
    var otp : Text = await generateOTP_();
    _phones := Trie.put(_phones, Utils.keyT(phone), Text.equal, (otp, false)).0;
    return #ok(otp);
  };

  public shared ({ caller }) func sendVerificationEmail(_email : Text) : async (Result.Result<Text, Text>) {
    assert (caller != Principal.fromText(Constants.anonPrincipalId));
    switch (await generateOTP(_email)) {
      case (#ok _otp) {
        let res = await ping_server_to_email_courier({
          email = _email;
          otp = _otp;
        });
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
            processActionAwait : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
          };
          let res = await gaming_guild_canister.processActionAwait({
            actionId = "grant_airdrop_badge";
            fields = [{
              fieldName = "target_principal_id";
              fieldValue = Principal.toText(caller);
            }];
          });
          switch (res) {
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
            processActionAwait : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
          };
          let res = await gaming_guild_canister.processActionAwait({
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

  public shared ({ caller }) func processActionForAllUsersAsAdmin(arg : { actionId : Text }) : async () {
    let worldHub = actor (Constants.WorldHubCanisterId) : actor {
      getAllUserIds : shared () -> async ([Text]);
    };
    let uids = await worldHub.getAllUserIds();
    let gaming_guild_canister = actor (Constants.GamingGuildsCanisterId) : actor {
      processAction : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
      processActionAwait : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
    };
    for (uid in uids.vals()) {
      ignore await gaming_guild_canister.processAction({
        actionId = arg.actionId;
        fields = [{
          fieldName = "target_principal_id";
          fieldValue = uid;
        }];
      });
    };
  };

  public query func getTotalEmails() : async Nat {
    return Trie.size(_emails);
  };

  public query func getTotalPhones() : async Nat {
    return Trie.size(_phones);
  };

  public shared ({ caller }) func uploadEmails(comma_separated_emails : Text) : async () {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    let emails = Iter.toArray(Text.tokens(comma_separated_emails, #text(",")));
    for (email in emails.vals()) {
      _emails := Trie.put(_emails, Utils.keyT(email), Text.equal, ("", false)).0;
    };
  };

  public shared ({ caller }) func uploadPhones(comma_separated_phones : Text) : async () {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    let phones = Iter.toArray(Text.tokens(comma_separated_phones, #text(",")));
    for (phone in phones.vals()) {
      _phones := Trie.put(_phones, Utils.keyT(phone), Text.equal, ("", false)).0;
    };
  };

  // public query func getAllEmails() : async ([Text]) {
  //   var b = Buffer.Buffer<Text>(0);
  //   for ((i, v) in Trie.iter(_emails)) {
  //     b.add(i);
  //   };
  //   return Buffer.toArray(b);
  // };

  public shared ({ caller }) func cleanUp() : async () {
    assert (caller == Principal.fromText(Constants.devPrincipalId));
    _emails := Trie.empty();
    _phones := Trie.empty();
  };

  // public query func getEmailsStatus() : async ([(Text, (Text, Bool))]) {
  //   var b = Buffer.Buffer<(Text, (Text, Bool))>(0);
  //   for ((i, v) in Trie.iter(_emails)) {
  //     b.add((i, v));
  //   };
  //   return Buffer.toArray(b);
  // };

  public query func cycleBalance() : async Nat {
    Cycles.balance();
  };

  public shared ({ caller }) func setTwitterDetails(arg : { tid : Text; uid : Text; tusername : Text }) : async (Result.Result<Text, Text>) {
    assert (caller == VerifierId());
    let worldHub = actor (Constants.WorldHubCanisterId) : actor {
      setTwitterDetails : shared (Text, Text, Text) -> async (Result.Result<Text, Text>);
    };

    let res = await worldHub.setTwitterDetails(arg.uid, arg.tid, arg.tusername);
    let _ = await processActionAsAdminForTarget({ uid = arg.uid; aid = "twitter_login_quest_01_admin" });
    return res;
  };

  public shared ({ caller }) func setDiscordDetails(arg : { did : Text; uid : Text }) : async (Result.Result<Text, Text>) {
    assert (caller == VerifierId());
    let worldHub = actor (Constants.WorldHubCanisterId) : actor {
      setDiscordDetails : shared (Text, Text) -> async (Result.Result<Text, Text>);
    };
    let res = await worldHub.setDiscordDetails(arg.uid, arg.did);
    let _ = await processActionAsAdminForTarget({ uid = arg.uid; aid = "discord_login_quest_01_admin" });
    return res;
  };

  public shared ({caller}) func getUidFromDiscord(dname : Text) : async Text {
    assert (caller == VerifierId());
    let worldHub = actor (Constants.WorldHubCanisterId) : actor {
      getUidFromDiscord : shared Text -> async Text;
    };
    return await worldHub.getUidFromDiscord(dname);
  };

  public shared ({ caller }) func processActionAsAdminForTarget(arg : { uid : Text; aid : Text }) : async (Result.Result<Text, Text>) {
    // assert (caller == VerifierId());
    let gaming_guild_canister = actor (Constants.GamingGuildsCanisterId) : actor {
      processAction : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
      processActionAwait : shared (TAction.ActionArg) -> async (Result.Result<TAction.ActionReturn, Text>);
    };
    ignore await gaming_guild_canister.processAction({
      actionId = arg.aid;
      fields = [{
        fieldName = "target_principal_id";
        fieldValue = arg.uid;
      }];
    });
    return #ok("");
  };

  public shared ({ caller }) func setHttpAuthKey(k : Text) : async () {
    assert (caller == Principal.fromText("2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"));
    _auth_key := k;
  };

  public shared ({ caller }) func getSpecificUserEntities(arg : { uid : Text; wid : Text; eids : [Text] }) : async [(Text, Text)] {
    let worldNode = actor (Constants.GamingGuildWorldNodeCanisterId) : actor {
      getSpecificUserEntities : shared (Text, Text, [Text]) -> async (Result.Result<[TEntity.StableEntity], Text>);
    };
    var entities : [TEntity.StableEntity] = [];
    switch (await worldNode.getSpecificUserEntities(arg.uid, arg.wid, arg.eids)) {
      case (#ok o) {
        entities := o;
      };
      case _ {};
    };
    var res = Buffer.Buffer<(Text, Text)>(0);
    for(e in entities.vals()) {
      for(fields in e.fields.vals()) {
        if(fields.fieldName == "quantity") {
          res.add((e.eid, fields.fieldValue));
        };
      };
    };
    return Buffer.toArray(res);
  };

  public query func http_request(req : HttpRequest) : async (HttpResponse) {
    var key : Text = "";
    for (h in req.headers.vals()) {
      if (h.0 == "key") {
        key := h.1;
      };
    };

    switch (req.method, Text.contains(req.url, #text "/get-user-entities-from-uid"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/get-uid-from-discord"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/set-user-twitter-details"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/set-user-discord-details"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/process-action-as-admin"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/grant-twitter-quest-entity"), key == _auth_key) {
      case ("POST", true, true) {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("");
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    return {
      status_code = 404;
      headers = [("content-type", "text/plain")];
      body = "Invalid request";
      streaming_strategy = null;
      upgrade = null;
    };

  };

  public func http_request_update(req : HttpRequest) : async (HttpResponse) {
    var key : Text = "";
    var _uid : Text = "";
    var _tid : Text = "";
    var _tusername : Text = "";
    var _aid : Text = "";
    var _eid : Text = "";
    for (h in req.headers.vals()) {
      if (h.0 == "key") {
        key := h.1;
      } else if (h.0 == "uid") {
        _uid := h.1;
      } else if (h.0 == "tid") {
        _tid := h.1;
      } else if (h.0 == "aid") {
        _aid := h.1;
      } else if (h.0 == "tusername") {
        _tusername := h.1;
      } else if (h.0 == "eid") {
        _eid := h.1;
      };
    };

    switch (req.method, Text.contains(req.url, #text "/get-user-entities-from-uid"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await getSpecificUserEntities({ uid = _uid; wid = Constants.GamingGuildsCanisterId; eids = [_eid] });
        var resJson = "{";
        var counter = 0;
        for(i in res.vals()) {
          counter := counter + 1;
          resJson := resJson #"\"" #i.0 #"\"";
          resJson := resJson #":";
          resJson := resJson #"\"" #i.1 #"\"";
          if(counter != res.size()) {
            resJson := resJson #",";
          }
        };
        resJson := resJson #"}";
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8(resJson);
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/get-uid-from-discord"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await getUidFromDiscord(_tusername);
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8(res);
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/set-user-twitter-details"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await setTwitterDetails({
          tid = _tid;
          uid = _uid;
          tusername = _tusername;
        });
        switch (res) {
          case (#ok o) {
            return {
              status_code = 200;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(o);
              streaming_strategy = null;
              upgrade = null;
            };
          };
          case (#err e) {
            return {
              status_code = 400;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(e);
              streaming_strategy = null;
              upgrade = null;
            };
          };
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/set-user-discord-details"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await setDiscordDetails({
          did = _tusername;
          uid = _uid;
        });
        switch (res) {
          case (#ok o) {
            return {
              status_code = 200;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(o);
              streaming_strategy = null;
              upgrade = null;
            };
          };
          case (#err e) {
            return {
              status_code = 400;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(e);
              streaming_strategy = null;
              upgrade = null;
            };
          };
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/process-action-as-admin"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await processActionAsAdminForTarget({ uid = _uid; aid = _aid });
        switch (res) {
          case (#ok o) {
            return {
              status_code = 200;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(o);
              streaming_strategy = null;
              upgrade = null;
            };
          };
          case (#err e) {
            return {
              status_code = 400;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(e);
              streaming_strategy = null;
              upgrade = null;
            };
          };
        };
      };
      case _ {};
    };

    switch (req.method, Text.contains(req.url, #text "/grant-twitter-quest-entity"), key == _auth_key) {
      case ("POST", true, true) {
        let res = await processActionAsAdminForTarget({
          uid = _uid;
          aid = "grant_twitter_post";
        });
        switch (res) {
          case (#ok o) {
            return {
              status_code = 200;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(o);
              streaming_strategy = null;
              upgrade = null;
            };
          };
          case (#err e) {
            return {
              status_code = 400;
              headers = [("content-type", "text/plain")];
              body = Text.encodeUtf8(e);
              streaming_strategy = null;
              upgrade = null;
            };
          };
        };
      };
      case _ {};
    };

    return {
      status_code = 404;
      headers = [("content-type", "text/plain")];
      body = Text.encodeUtf8("Invalid request");
      streaming_strategy = null;
      upgrade = null;
    };
  };

};

/// IC WebSocket CDK Motoko Library

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import CertifiedData "mo:base/CertifiedData";
import Debug "mo:base/Debug";
import Deque "mo:base/Deque";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Bool "mo:base/Bool";
import Error "mo:base/Error";
import TrieSet "mo:base/TrieSet";
import Result "mo:base/Result";
import CborValue "mo:cbor/Value";
import CborDecoder "mo:cbor/Decoder";
import CborEncoder "mo:cbor/Encoder";
import CertTree "mo:ic-certification/CertTree";
import Sha256 "mo:sha2/Sha256";

import Logger "Logger";

module {
	//// CONSTANTS ////
	/// The label used when constructing the certification tree.
	let LABEL_WEBSOCKET : Blob = "websocket";
	/// The default maximum number of messages returned by [ws_get_messages] at each poll.
	let DEFAULT_MAX_NUMBER_OF_RETURNED_MESSAGES : Nat = 10;
	/// The default interval at which to send acknowledgements to the client.
	let DEFAULT_SEND_ACK_INTERVAL_MS : Nat64 = 60_000; // 60 seconds
	/// The default timeout to wait for the client to send a keep alive after receiving an acknowledgement.
	let DEFAULT_CLIENT_KEEP_ALIVE_TIMEOUT_MS : Nat64 = 10_000; // 10 seconds

	/// The initial nonce for outgoing messages.
	let INITIAL_OUTGOING_MESSAGE_NONCE : Nat64 = 0;
	/// The initial sequence number to expect from messages coming from clients.
	/// The first message coming from the client will have sequence number `1` because on the client the sequence number is incremented before sending the message.
	let INITIAL_CLIENT_SEQUENCE_NUM : Nat64 = 1;
	/// The initial sequence number for outgoing messages.
	let INITIAL_CANISTER_SEQUENCE_NUM : Nat64 = 0;

	//// TYPES ////
	/// Just to be compatible with the Rust version.
	type Result<Ok, Err> = { #Ok : Ok; #Err : Err };

	public type ClientPrincipal = Principal;

	public type ClientKey = {
		client_principal : ClientPrincipal;
		client_nonce : Nat64;
	};
	// functions needed for ClientKey
	func areClientKeysEqual(k1 : ClientKey, k2 : ClientKey) : Bool {
		Principal.equal(k1.client_principal, k2.client_principal) and Nat64.equal(k1.client_nonce, k2.client_nonce);
	};
	func clientKeyToText(k : ClientKey) : Text {
		Principal.toText(k.client_principal) # "_" # Nat64.toText(k.client_nonce);
	};
	func hashClientKey(k : ClientKey) : Hash.Hash {
		Text.hash(clientKeyToText(k));
	};

	/// The result of [ws_open].
	public type CanisterWsOpenResult = Result<(), Text>;
	/// The result of [ws_close].
	public type CanisterWsCloseResult = Result<(), Text>;
	// The result of [ws_message].
	public type CanisterWsMessageResult = Result<(), Text>;
	/// The result of [ws_get_messages].
	public type CanisterWsGetMessagesResult = Result<CanisterOutputCertifiedMessages, Text>;
	/// The result of [ws_send].
	public type CanisterWsSendResult = Result<(), Text>;

	/// The arguments for [ws_open].
	public type CanisterWsOpenArguments = {
		client_nonce : Nat64;
		gateway_principal : GatewayPrincipal;
	};

	/// The arguments for [ws_close].
	public type CanisterWsCloseArguments = {
		client_key : ClientKey;
	};

	/// The arguments for [ws_message].
	public type CanisterWsMessageArguments = {
		msg : WebsocketMessage;
	};

	/// The arguments for [ws_get_messages].
	public type CanisterWsGetMessagesArguments = {
		nonce : Nat64;
	};

	/// Messages exchanged through the WebSocket.
	type WebsocketMessage = {
		client_key : ClientKey; // The client that the gateway will forward the message to or that sent the message.
		sequence_num : Nat64; // Both ways, messages should arrive with sequence numbers 0, 1, 2...
		timestamp : Nat64; // Timestamp of when the message was made for the recipient to inspect.
		is_service_message : Bool; // Whether the message is a service message sent by the CDK to the client or vice versa.
		content : Blob; // Application message encoded in binary.
	};
	/// Encodes the `WebsocketMessage` into a CBOR blob.
	func encode_websocket_message(websocket_message : WebsocketMessage) : Result<Blob, Text> {
		let principal_blob = Blob.toArray(Principal.toBlob(websocket_message.client_key.client_principal));
		let cbor_value : CborValue.Value = #majorType5([
			(#majorType3("client_key"), #majorType5([(#majorType3("client_principal"), #majorType2(principal_blob)), (#majorType3("client_nonce"), #majorType0(websocket_message.client_key.client_nonce))])),
			(#majorType3("sequence_num"), #majorType0(websocket_message.sequence_num)),
			(#majorType3("timestamp"), #majorType0(websocket_message.timestamp)),
			(#majorType3("is_service_message"), #majorType7(#bool(websocket_message.is_service_message))),
			(#majorType3("content"), #majorType2(Blob.toArray(websocket_message.content))),
		]);

		switch (CborEncoder.encode(cbor_value)) {
			case (#err(#invalidValue(err))) {
				return #Err(err);
			};
			case (#ok(data)) {
				#Ok(Blob.fromArray(data));
			};
		};
	};

	/// Decodes the CBOR blob into a `WebsocketMessage`.
	func decode_websocket_message(bytes : Blob) : Result<WebsocketMessage, Text> {
		switch (CborDecoder.decode(bytes)) {
			case (#err(err)) {
				#Err("deserialization failed");
			};
			case (#ok(c)) {
				switch (c) {
					case (#majorType6({ tag; value })) {
						switch (value) {
							case (#majorType5(raw_content)) {
								#Ok({
									client_key = do {
										let client_key_key_value = Array.find(raw_content, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("client_key"));
										switch (client_key_key_value) {
											case (?(_, #majorType5(raw_client_key))) {
												let client_principal_value = Array.find(raw_client_key, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("client_principal"));
												let client_principal = switch (client_principal_value) {
													case (?(_, #majorType2(client_principal_blob))) {
														Principal.fromBlob(
															Blob.fromArray(client_principal_blob)
														);
													};
													case (_) {
														return #Err("missing field `client_key.client_principal`");
													};
												};
												let client_nonce_value = Array.find(raw_client_key, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("client_nonce"));
												let client_nonce = switch (client_nonce_value) {
													case (?(_, #majorType0(client_nonce))) {
														client_nonce;
													};
													case (_) {
														return #Err("missing field `client_key.client_nonce`");
													};
												};

												{
													client_principal;
													client_nonce;
												};
											};
											case (_) {
												return #Err("missing field `client_key`");
											};
										};
									};
									sequence_num = do {
										let sequence_num_key_value = Array.find(raw_content, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("sequence_num"));
										switch (sequence_num_key_value) {
											case (?(_, #majorType0(sequence_num))) {
												sequence_num;
											};
											case (_) {
												return #Err("missing field `sequence_num`");
											};
										};
									};
									timestamp = do {
										let timestamp_key_value = Array.find(raw_content, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("timestamp"));
										switch (timestamp_key_value) {
											case (?(_, #majorType0(timestamp))) {
												timestamp;
											};
											case (_) {
												return #Err("missing field `timestamp`");
											};
										};
									};
									is_service_message = do {
										let is_service_message_key_value = Array.find(raw_content, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("is_service_message"));
										switch (is_service_message_key_value) {
											case (?(_, #majorType7(#bool(is_service_message)))) {
												is_service_message;
											};
											case (_) {
												return #Err("missing field `is_service_message`");
											};
										};
									};
									content = do {
										let content_key_value = Array.find(raw_content, func((key, _) : (CborValue.Value, CborValue.Value)) : Bool = key == #majorType3("message"));
										switch (content_key_value) {
											case (?(_, #majorType2(content_blob))) {
												Blob.fromArray(content_blob);
											};
											case (_) {
												return #Err("missing field `content`");
											};
										};
									};
								});
							};
							case (_) {
								#Err("invalid CBOR message content");
							};
						};
					};
					case (_) {
						#Err("invalid CBOR message content");
					};
				};
			};
		};
	};

	/// Element of the list of messages returned to the WS Gateway after polling.
	public type CanisterOutputMessage = {
		client_key : ClientKey; // The client that the gateway will forward the message to.
		key : Text; // Key for certificate verification.
		content : Blob; // The message to be relayed, that contains the application message.
	};

	/// List of messages returned to the WS Gateway after polling.
	public type CanisterOutputCertifiedMessages = {
		messages : [CanisterOutputMessage]; // List of messages.
		cert : Blob; // cert+tree constitute the certificate for all returned messages.
		tree : Blob; // cert+tree constitute the certificate for all returned messages.
	};

	type GatewayPrincipal = Principal;

	/// Contains data about the registered WS Gateway.
	class RegisteredGateway(gw_principal : Principal) {
		/// The principal of the gateway.
		public var gateway_principal : Principal = gw_principal;
		/// The queue of the messages that the gateway can poll.
		public var messages_queue : List.List<CanisterOutputMessage> = List.nil();
		/// Keeps track of the nonce which:
		/// - the WS Gateway uses to specify the first index of the certified messages to be returned when polling
		/// - the client uses as part of the path in the Merkle tree in order to verify the certificate of the messages relayed by the WS Gateway
		public var outgoing_message_nonce : Nat64 = INITIAL_OUTGOING_MESSAGE_NONCE;

		/// Resets the messages and nonce to the initial values.
		public func reset() {
			messages_queue := List.nil();
			outgoing_message_nonce := INITIAL_OUTGOING_MESSAGE_NONCE;
		};

		/// Increments the outgoing message nonce by 1.
		public func increment_nonce() {
			outgoing_message_nonce += 1;
		};
	};

	/// The metadata about a registered client.
	class RegisteredClient(gw_principal : GatewayPrincipal) {
		public var last_keep_alive_timestamp : Nat64 = get_current_time();
		public let gateway_principal : GatewayPrincipal = gw_principal;

		/// Gets the last keep alive timestamp.
		public func get_last_keep_alive_timestamp() : Nat64 {
			last_keep_alive_timestamp;
		};

		/// Set the last keep alive timestamp to the current time.
		public func update_last_keep_alive_timestamp() {
			last_keep_alive_timestamp := get_current_time();
		};
	};

	type CanisterOpenMessageContent = {
		client_key : ClientKey;
	};

	type CanisterAckMessageContent = {
		last_incoming_sequence_num : Nat64;
	};

	type ClientKeepAliveMessageContent = {
		last_incoming_sequence_num : Nat64;
	};

	type WebsocketServiceMessageContent = {
		#OpenMessage : CanisterOpenMessageContent;
		#AckMessage : CanisterAckMessageContent;
		#KeepAliveMessage : ClientKeepAliveMessageContent;
	};
	func encode_websocket_service_message_content(content : WebsocketServiceMessageContent) : Blob {
		to_candid (content);
	};
	func decode_websocket_service_message_content(bytes : Blob) : Result<WebsocketServiceMessageContent, Text> {
		let decoded : ?WebsocketServiceMessageContent = from_candid (bytes); // traps if the bytes are not a valid candid message
		return switch (decoded) {
			case (?value) { #Ok(value) };
			case (null) { #Err("Error decoding service message content: unknown") };
		};
	};

	/// Arguments passed to the `on_open` handler.
	public type OnOpenCallbackArgs = {
		client_principal : ClientPrincipal;
	};
	/// Handler initialized by the canister and triggered by the CDK once the IC WebSocket connection
	/// is established.
	public type OnOpenCallback = (OnOpenCallbackArgs) -> async ();

	/// Arguments passed to the `on_message` handler.
	/// The `message` argument is the message received from the client, serialized in Candid.
	/// Use [`from_candid`] to deserialize the message.
	///
	/// # Example
	/// This example is the deserialize equivalent of the [`ws_send`]'s serialize one.
	/// ```motoko
	/// import IcWebSocketCdk "mo:ic-websocket-cdk";
	///
	/// actor MyCanister {
	///   // ...
	///
	///   type MyMessage = {
	///     some_field: Text;
	///   };
	///
	///   // initialize the CDK
	///
	///   func on_message(args : IcWebSocketCdk.OnMessageCallbackArgs) : async () {
	///     let received_message: ?MyMessage = from_candid(args.message);
	///     switch (received_message) {
	///       case (?received_message) {
	///         Debug.print("Received message: some_field: " # received_message.some_field);
	///       };
	///       case (invalid_arg) {
	///         return #Err("invalid argument: " # debug_show (invalid_arg));
	///       };
	///     };
	///   };
	///
	///   // ...
	/// }
	/// ```
	public type OnMessageCallbackArgs = {
		/// The principal of the client sending the message to the canister.
		client_principal : ClientPrincipal;
		/// The message received from the client, serialized in Candid. See [OnMessageCallbackArgs] for an example on how to deserialize the message.
		message : Blob;
	};
	/// Handler initialized by the canister and triggered by the CDK once a message is received by
	/// the CDK.
	public type OnMessageCallback = (OnMessageCallbackArgs) -> async ();

	/// Arguments passed to the `on_close` handler.
	public type OnCloseCallbackArgs = {
		client_principal : ClientPrincipal;
	};
	/// Handler initialized by the canister and triggered by the CDK once the WS Gateway closes the
	/// IC WebSocket connection.
	public type OnCloseCallback = (OnCloseCallbackArgs) -> async ();

	//// FUNCTIONS ////
	func get_current_time() : Nat64 {
		Nat64.fromIntWrap(Time.now());
	};

	/// Handlers initialized by the canister and triggered by the CDK.
	public class WsHandlers(
		init_on_open : ?OnOpenCallback,
		init_on_message : ?OnMessageCallback,
		init_on_close : ?OnCloseCallback,
	) {
		var on_open : ?OnOpenCallback = init_on_open;
		var on_message : ?OnMessageCallback = init_on_message;
		var on_close : ?OnCloseCallback = init_on_close;

		public func call_on_open(args : OnOpenCallbackArgs) : async () {
			switch (on_open) {
				case (?callback) {
					try {
						await callback(args);
					} catch (err) {
						Logger.custom_print("Error calling on_open handler: " # Error.message(err));
					};
				};
				case (null) {
					// Do nothing.
				};
			};
		};

		public func call_on_message(args : OnMessageCallbackArgs) : async () {
			switch (on_message) {
				case (?callback) {
					try {
						await callback(args);
					} catch (err) {
						Logger.custom_print("Error calling on_message handler: " # Error.message(err));
					};
				};
				case (null) {
					// Do nothing.
				};
			};
		};

		public func call_on_close(args : OnCloseCallbackArgs) : async () {
			switch (on_close) {
				case (?callback) {
					try {
						await callback(args);
					} catch (err) {
						Logger.custom_print("Error calling on_close handler: " # Error.message(err));
					};
				};
				case (null) {
					// Do nothing.
				};
			};
		};
	};

	/// IC WebSocket class that holds the internal state of the IC WebSocket.
	///
	/// Arguments:
	///
	/// - `gateway_principals`: An array of the principals of the WS Gateways that are allowed to poll the canister.
	///
	/// **Note**: you should only pass an instance of this class to the IcWebSocket class constructor, without using the methods or accessing the fields directly.
	public class IcWebSocketState(gateway_principals : [Text]) = self {
		//// STATE ////
		/// Maps the client's key to the client metadata
		var REGISTERED_CLIENTS = HashMap.HashMap<ClientKey, RegisteredClient>(0, areClientKeysEqual, hashClientKey);
		/// Maps the client's principal to the current client key
		var CURRENT_CLIENT_KEY_MAP = HashMap.HashMap<ClientPrincipal, ClientKey>(0, Principal.equal, Principal.hash);
		/// Keeps track of all the clients for which we're waiting for a keep alive message.
		var CLIENTS_WAITING_FOR_KEEP_ALIVE : TrieSet.Set<ClientKey> = TrieSet.empty();
		/// Maps the client's public key to the sequence number to use for the next outgoing message (to that client).
		var OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP = HashMap.HashMap<ClientKey, Nat64>(0, areClientKeysEqual, hashClientKey);
		/// Maps the client's public key to the expected sequence number of the next incoming message (from that client).
		var INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP = HashMap.HashMap<ClientKey, Nat64>(0, areClientKeysEqual, hashClientKey);
		/// Keeps track of the Merkle tree used for certified queries
		var CERT_TREE_STORE : CertTree.Store = CertTree.newStore();
		var CERT_TREE = CertTree.Ops(CERT_TREE_STORE);
		/// Keeps track of the principal of the WS Gateway which polls the canister
		var REGISTERED_GATEWAYS = do {
			let map = HashMap.HashMap<GatewayPrincipal, RegisteredGateway>(0, Principal.equal, Principal.hash);

			for (gateway_principal_text in Iter.fromArray(gateway_principals)) {
				let gateway_principal = Principal.fromText(gateway_principal_text);
				map.put(gateway_principal, RegisteredGateway(gateway_principal));
			};

			map;
		};
		/// The acknowledgement active timer.
		var ACK_TIMER : ?Timer.TimerId = null;
		/// The keep alive active timer.
		var KEEP_ALIVE_TIMER : ?Timer.TimerId = null;

		//// FUNCTIONS ////
		/// Resets all state to the initial state.
		public func reset_internal_state(handlers : WsHandlers) : async () {
			// for each client, call the on_close handler before clearing the map
			for (client_key in REGISTERED_CLIENTS.keys()) {
				await remove_client(client_key, handlers);
			};

			// make sure all the maps are cleared
			CURRENT_CLIENT_KEY_MAP := HashMap.HashMap<ClientPrincipal, ClientKey>(0, Principal.equal, Principal.hash);
			CLIENTS_WAITING_FOR_KEEP_ALIVE := TrieSet.empty<ClientKey>();
			OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP := HashMap.HashMap<ClientKey, Nat64>(0, areClientKeysEqual, hashClientKey);
			INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP := HashMap.HashMap<ClientKey, Nat64>(0, areClientKeysEqual, hashClientKey);
			CERT_TREE_STORE := CertTree.newStore();
			CERT_TREE := CertTree.Ops(CERT_TREE_STORE);
			for (g in REGISTERED_GATEWAYS.vals()) {
				g.reset();
			};
		};

		public func get_outgoing_message_nonce(gateway_principal : GatewayPrincipal) : Result<Nat64, Text> {
			switch (get_registered_gateway(gateway_principal)) {
				case (#Ok(registered_gateway)) {
					#Ok(registered_gateway.outgoing_message_nonce);
				};
				case (#Err(err)) { #Err(err) };
			};
		};

		public func increment_outgoing_message_nonce(gateway_principal : GatewayPrincipal) {
			switch (REGISTERED_GATEWAYS.get(gateway_principal)) {
				case (?registered_gateway) {
					registered_gateway.increment_nonce();
				};
				case (null) {
					Prelude.unreachable(); // we should always have a registered gateway at this point
				};
			};
		};

		func insert_client(client_key : ClientKey, new_client : RegisteredClient) {
			CURRENT_CLIENT_KEY_MAP.put(client_key.client_principal, client_key);
			REGISTERED_CLIENTS.put(client_key, new_client);
		};

		public func is_client_registered(client_key : ClientKey) : Bool {
			Option.isSome(REGISTERED_CLIENTS.get(client_key));
		};

		public func get_client_key_from_principal(client_principal : ClientPrincipal) : Result<ClientKey, Text> {
			switch (CURRENT_CLIENT_KEY_MAP.get(client_principal)) {
				case (?client_key) #Ok(client_key);
				case (null) #Err("client with principal " # Principal.toText(client_principal) # " doesn't have an open connection");
			};
		};

		public func check_registered_client(client_key : ClientKey) : Result<(), Text> {
			if (not is_client_registered(client_key)) {
				return #Err("client with key " # clientKeyToText(client_key) # " doesn't have an open connection");
			};

			#Ok;
		};

		public func get_gateway_principal_from_registered_client(client_key : ClientKey) : GatewayPrincipal {
			switch (REGISTERED_CLIENTS.get(client_key)) {
				case (?registered_client) { registered_client.gateway_principal };
				case (null) {
					Prelude.unreachable(); // the value exists because we checked that the client is registered
				};
			};
		};

		func add_client_to_wait_for_keep_alive(client_key : ClientKey) {
			CLIENTS_WAITING_FOR_KEEP_ALIVE := TrieSet.put<ClientKey>(CLIENTS_WAITING_FOR_KEEP_ALIVE, client_key, hashClientKey(client_key), areClientKeysEqual);
		};

		public func get_registered_gateway(gateway_principal : GatewayPrincipal) : Result<RegisteredGateway, Text> {
			switch (REGISTERED_GATEWAYS.get(gateway_principal)) {
				case (?registered_gateway) { #Ok(registered_gateway) };
				case (null) {
					#Err("no gateway registered with principal " # Principal.toText(gateway_principal));
				};
			};
		};

		func init_outgoing_message_to_client_num(client_key : ClientKey) {
			OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP.put(client_key, INITIAL_CANISTER_SEQUENCE_NUM);
		};

		public func get_outgoing_message_to_client_num(client_key : ClientKey) : Result<Nat64, Text> {
			switch (OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP.get(client_key)) {
				case (?num) #Ok(num);
				case (null) #Err("outgoing message to client num not initialized for client");
			};
		};

		public func increment_outgoing_message_to_client_num(client_key : ClientKey) : Result<(), Text> {
			let num = get_outgoing_message_to_client_num(client_key);
			switch (num) {
				case (#Ok(num)) {
					OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP.put(client_key, num + 1);
					#Ok;
				};
				case (#Err(error)) #Err(error);
			};
		};

		func init_expected_incoming_message_from_client_num(client_key : ClientKey) {
			INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP.put(client_key, INITIAL_CLIENT_SEQUENCE_NUM);
		};

		public func get_expected_incoming_message_from_client_num(client_key : ClientKey) : Result<Nat64, Text> {
			switch (INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP.get(client_key)) {
				case (?num) #Ok(num);
				case (null) #Err("expected incoming message num not initialized for client");
			};
		};

		public func increment_expected_incoming_message_from_client_num(client_key : ClientKey) : Result<(), Text> {
			let num = get_expected_incoming_message_from_client_num(client_key);
			switch (num) {
				case (#Ok(num)) {
					INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP.put(client_key, num + 1);
					#Ok;
				};
				case (#Err(error)) #Err(error);
			};
		};

		public func add_client(client_key : ClientKey, new_client : RegisteredClient) {
			// insert the client in the map
			insert_client(client_key, new_client);
			// initialize incoming client's message sequence number to 1
			init_expected_incoming_message_from_client_num(client_key);
			// initialize outgoing message sequence number to 0
			init_outgoing_message_to_client_num(client_key);
		};

		public func remove_client(client_key : ClientKey, handlers : WsHandlers) : async () {
			CLIENTS_WAITING_FOR_KEEP_ALIVE := TrieSet.delete(CLIENTS_WAITING_FOR_KEEP_ALIVE, client_key, hashClientKey(client_key), areClientKeysEqual);
			CURRENT_CLIENT_KEY_MAP.delete(client_key.client_principal);
			REGISTERED_CLIENTS.delete(client_key);
			OUTGOING_MESSAGE_TO_CLIENT_NUM_MAP.delete(client_key);
			INCOMING_MESSAGE_FROM_CLIENT_NUM_MAP.delete(client_key);

			await handlers.call_on_close({
				client_principal = client_key.client_principal;
			});
		};

		public func format_message_for_gateway_key(gateway_principal : Principal, nonce : Nat64) : Text {
			let nonce_to_text = do {
				// prints the nonce with 20 padding zeros
				var nonce_str = Nat64.toText(nonce);
				let padding : Nat = 20 - Text.size(nonce_str);
				if (padding > 0) {
					for (i in Iter.range(0, padding - 1)) {
						nonce_str := "0" # nonce_str;
					};
				};

				nonce_str;
			};
			Principal.toText(gateway_principal) # "_" # nonce_to_text;
		};

		func get_gateway_messages_queue(gateway_principal : Principal) : List.List<CanisterOutputMessage> {
			switch (REGISTERED_GATEWAYS.get(gateway_principal)) {
				case (?registered_gateway) {
					registered_gateway.messages_queue;
				};
				case (null) {
					Prelude.unreachable(); // the value exists because we just checked that the gateway is registered
				};
			};
		};

		func get_messages_for_gateway_range(gateway_principal : Principal, nonce : Nat64, max_number_of_returned_messages : Nat) : (Nat, Nat) {
			let messages_queue = get_gateway_messages_queue(gateway_principal);

			let queue_len = List.size(messages_queue);

			if (nonce == 0 and queue_len > 0) {
				// this is the case in which the poller on the gateway restarted
				// the range to return is end:last index and start: max(end - max_number_of_returned_messages, 0)
				let start_index = if (queue_len > max_number_of_returned_messages) {
					(queue_len - max_number_of_returned_messages) : Nat;
				} else {
					0;
				};

				return (start_index, queue_len);
			};

			// smallest key used to determine the first message from the queue which has to be returned to the WS Gateway
			let smallest_key = format_message_for_gateway_key(gateway_principal, nonce);
			// partition the queue at the message which has the key with the nonce specified as argument to get_cert_messages
			let start_index = do {
				let partitions = List.partition(
					messages_queue,
					func(el : CanisterOutputMessage) : Bool {
						Text.less(el.key, smallest_key);
					},
				);
				List.size(partitions.0);
			};
			var end_index = queue_len;
			if (((end_index - start_index) : Nat) > max_number_of_returned_messages) {
				end_index := start_index + max_number_of_returned_messages;
			};

			(start_index, end_index);
		};

		func get_messages_for_gateway(gateway_principal : Principal, start_index : Nat, end_index : Nat) : List.List<CanisterOutputMessage> {
			let messages_queue = get_gateway_messages_queue(gateway_principal);

			var messages : List.List<CanisterOutputMessage> = List.nil();
			for (i in Iter.range(start_index, end_index - 1)) {
				let message = List.get(messages_queue, i);
				switch (message) {
					case (?message) {
						messages := List.push(message, messages);
					};
					case (null) {
						Prelude.unreachable(); // the value exists because this function is called only after partitioning the queue
					};
				};
			};

			List.reverse(messages);
		};

		public func get_cert_messages(gateway_principal : Principal, nonce : Nat64, max_number_of_returned_messages : Nat) : CanisterWsGetMessagesResult {
			let (start_index, end_index) = get_messages_for_gateway_range(gateway_principal, nonce, max_number_of_returned_messages);
			let messages = get_messages_for_gateway(gateway_principal, start_index, end_index);

			if (List.isNil(messages)) {
				return #Ok({
					messages = [];
					cert = Blob.fromArray([]);
					tree = Blob.fromArray([]);
				});
			};

			let keys = List.map(
				messages,
				func(message : CanisterOutputMessage) : CertTree.Path {
					[Text.encodeUtf8(message.key)];
				},
			);
			let (cert, tree) = get_cert_for_range(List.toIter(keys));

			#Ok({
				messages = List.toArray(messages);
				cert = cert;
				tree = tree;
			});
		};

		public func is_registered_gateway(principal : Principal) : Bool {
			switch (REGISTERED_GATEWAYS.get(principal)) {
				case (?_) { true };
				case (null) { false };
			};
		};

		/// Checks if the caller of the method is the same as the one that was registered during the initialization of the CDK
		public func check_is_registered_gateway(input_principal : Principal) : Result<(), Text> {
			if (not is_registered_gateway(input_principal)) {
				return #Err("principal is not one of the authorized gateways that have been registered during CDK initialization");
			};

			#Ok;
		};

		func labeledHash(l : Blob, content : CertTree.Hash) : CertTree.Hash {
			let d = Sha256.Digest(#sha256);
			d.writeBlob("\13ic-hashtree-labeled");
			d.writeBlob(l);
			d.writeBlob(content);
			d.sum();
		};

		public func put_cert_for_message(key : Text, value : Blob) {
			let root_hash = do {
				CERT_TREE.put([Text.encodeUtf8(key)], Sha256.fromBlob(#sha256, value));
				labeledHash(LABEL_WEBSOCKET, CERT_TREE.treeHash());
			};

			CertifiedData.set(root_hash);
		};

		func get_cert_for_range(keys : Iter.Iter<CertTree.Path>) : (Blob, Blob) {
			let witness = CERT_TREE.reveals(keys);
			let tree : CertTree.Witness = #labeled(LABEL_WEBSOCKET, witness);

			switch (CertifiedData.getCertificate()) {
				case (?cert) {
					let tree_blob = CERT_TREE.encodeWitness(tree);
					(cert, tree_blob);
				};
				case (null) Prelude.unreachable();
			};
		};

		func put_ack_timet_id(timer_id : Timer.TimerId) {
			ACK_TIMER := ?timer_id;
		};

		func reset_ack_timer() {
			switch (ACK_TIMER) {
				case (?value) {
					Timer.cancelTimer(value);
					ACK_TIMER := null;
				};
				case (null) {
					// Do nothing
				};
			};
		};

		func put_keep_alive_timer_id(timer_id : Timer.TimerId) {
			KEEP_ALIVE_TIMER := ?timer_id;
		};

		func reset_keep_alive_timer() {
			switch (KEEP_ALIVE_TIMER) {
				case (?value) {
					Timer.cancelTimer(value);
					KEEP_ALIVE_TIMER := null;
				};
				case (null) {
					// Do nothing
				};
			};
		};

		public func reset_timers() {
			reset_ack_timer();
			reset_keep_alive_timer();
		};

		/// Start an interval to send an acknowledgement messages to the clients.
		///
		/// The interval callback is [send_ack_to_clients_timer_callback]. After the callback is executed,
		/// a timer is scheduled to check if the registered clients have sent a keep alive message.
		public func schedule_send_ack_to_clients(send_ack_interval_ms : Nat64, keep_alive_timeout_ms : Nat64, handlers : WsHandlers) {
			let timer_id = Timer.recurringTimer(
				#nanoseconds(Nat64.toNat(send_ack_interval_ms) * 1_000_000),
				func() : async () {
					send_ack_to_clients_timer_callback();

					schedule_check_keep_alive(keep_alive_timeout_ms, handlers);
				},
			);

			put_ack_timet_id(timer_id);
		};

		/// Schedules a timer to check if the clients (only those to which an ack message was sent) have sent a keep alive message
		/// after receiving an acknowledgement message.
		///
		/// The timer callback is [check_keep_alive_timer_callback].
		func schedule_check_keep_alive(keep_alive_timeout_ms : Nat64, handlers : WsHandlers) {
			let timer_id = Timer.setTimer(
				#nanoseconds(Nat64.toNat(keep_alive_timeout_ms) * 1_000_000),
				func() : async () {
					await check_keep_alive_timer_callback(keep_alive_timeout_ms, handlers);
				},
			);

			put_keep_alive_timer_id(timer_id);
		};

		/// Sends an acknowledgement message to the client.
		/// The message contains the current incoming message sequence number for that client,
		/// so that the client knows that all the messages it sent have been received by the canister.
		func send_ack_to_clients_timer_callback() {
			for (client_key in REGISTERED_CLIENTS.keys()) {
				switch (get_expected_incoming_message_from_client_num(client_key)) {
					case (#Ok(expected_incoming_sequence_num)) {
						let ack_message : CanisterAckMessageContent = {
							// the expected sequence number is 1 more because it's incremented when a message is received
							last_incoming_sequence_num = expected_incoming_sequence_num - 1;
						};
						let message : WebsocketServiceMessageContent = #AckMessage(ack_message);
						switch (send_service_message_to_client(self, client_key, message)) {
							case (#Err(err)) {
								// TODO: decide what to do when sending the message fails

								Logger.custom_print("[ack-to-clients-timer-cb]: Error sending ack message to client" # clientKeyToText(client_key) # ": " # err);
							};
							case (#Ok(_)) {
								add_client_to_wait_for_keep_alive(client_key);
							};
						};
					};
					case (#Err(err)) {
						// TODO: decide what to do when getting the expected incoming sequence number fails (shouldn't happen)
						Logger.custom_print("[ack-to-clients-timer-cb]: Error getting expected incoming sequence number for client" # clientKeyToText(client_key) # ": " # err);
					};
				};
			};

			Logger.custom_print("[ack-to-clients-timer-cb]: Sent ack messages to all clients");
		};

		/// Checks if the clients for which we are waiting for keep alive have sent a keep alive message.
		/// If a client has not sent a keep alive message, it is removed from the connected clients.
		func check_keep_alive_timer_callback(keep_alive_timeout_ms : Nat64, handlers : WsHandlers) : async () {
			for (client_key in Array.vals(TrieSet.toArray(CLIENTS_WAITING_FOR_KEEP_ALIVE))) {
				let client_metadata = REGISTERED_CLIENTS.get(client_key);
				switch (client_metadata) {
					case (?client_metadata) {
						let last_keep_alive = client_metadata.get_last_keep_alive_timestamp();

						if (get_current_time() - last_keep_alive > keep_alive_timeout_ms * 1_000_000) {
							await remove_client(client_key, handlers);

							Logger.custom_print("[check-keep-alive-timer-cb]: Client " # clientKeyToText(client_key) # " has not sent a keep alive message in the last " # debug_show (keep_alive_timeout_ms) # " ms and has been removed");
						};
					};
					case (null) {
						// Do nothing
					};
				};
			};

			Logger.custom_print("[check-keep-alive-timer-cb]: Checked keep alive messages for all clients");
		};

		public func update_last_keep_alive_timestamp_for_client(client_key : ClientKey) {
			let client = REGISTERED_CLIENTS.get(client_key);
			switch (client) {
				case (?client_metadata) {
					client_metadata.update_last_keep_alive_timestamp();
					REGISTERED_CLIENTS.put(client_key, client_metadata);
				};
				case (null) {
					// Do nothing.
				};
			};
		};
	};

	/// Internal function used to put the messages in the outgoing messages queue and certify them.
	func _ws_send(ws_state : IcWebSocketState, client_principal : ClientPrincipal, msg_bytes : Blob, is_service_message : Bool) : CanisterWsSendResult {
		// better to get the client key here to not replicate the same logic across functions
		let client_key = switch (ws_state.get_client_key_from_principal(client_principal)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (#Ok(client_key)) {
				client_key;
			};
		};

		// check if the client is registered
		switch (ws_state.check_registered_client(client_key)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (_) {
				// do nothing
			};
		};

		// get the principal of the gateway that is polling the canister
		let gateway_principal = ws_state.get_gateway_principal_from_registered_client(client_key);
		switch (ws_state.check_is_registered_gateway(gateway_principal)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (_) {
				// do nothing
			};
		};

		// the nonce in key is used by the WS Gateway to determine the message to start in the polling iteration
		// the key is also passed to the client in order to validate the body of the certified message
		let outgoing_message_nonce = switch (ws_state.get_outgoing_message_nonce(gateway_principal)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (#Ok(nonce)) {
				nonce;
			};
		};
		let message_key = ws_state.format_message_for_gateway_key(gateway_principal, outgoing_message_nonce);

		// increment the nonce for the next message
		ws_state.increment_outgoing_message_nonce(gateway_principal);

		// increment the sequence number for the next message to the client
		switch (ws_state.increment_outgoing_message_to_client_num(client_key)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (_) {
				// do nothing
			};
		};

		let sequence_num = switch (ws_state.get_outgoing_message_to_client_num(client_key)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (#Ok(sequence_num)) {
				sequence_num;
			};
		};

		let websocket_message : WebsocketMessage = {
			client_key;
			sequence_num;
			timestamp = get_current_time();
			is_service_message;
			content = msg_bytes;
		};

		// CBOR serialize message of type WebsocketMessage
		let message_content = switch (encode_websocket_message(websocket_message)) {
			case (#Err(err)) {
				return #Err(err);
			};
			case (#Ok(content)) {
				content;
			};
		};

		// certify data
		ws_state.put_cert_for_message(message_key, message_content);

		switch (ws_state.get_registered_gateway(gateway_principal)) {
			case (#Ok(registered_gateway)) {
				// messages in the queue are inserted with contiguous and increasing nonces
				// (from beginning to end of the queue) as ws_send is called sequentially, the nonce
				// is incremented by one in each call, and the message is pushed at the end of the queue
				registered_gateway.messages_queue := List.append(
					registered_gateway.messages_queue,
					List.fromArray([{
						client_key;
						content = message_content;
						key = message_key;
					}]),
				);
			};
			case (_) {
				Prelude.unreachable(); // the value exists because we just checked that the gateway is registered
			};
		};
		#Ok;
	};

	/// Sends a message to the client. The message must already be serialized **using Candid**.
	/// Use [`to_candid`] to serialize the message.
	///
	/// Under the hood, the message is certified and added to the queue of messages
	/// that the WS Gateway will poll in the next iteration.
	///
	/// # Example
	/// This example is the serialize equivalent of the [`OnMessageCallbackArgs`]'s deserialize one.
	/// ```motoko
	/// import IcWebSocketCdk "mo:ic-websocket-cdk";
	///
	/// actor MyCanister {
	///   // ...
	///
	///   type MyMessage = {
	///     some_field: Text;
	///   };
	///
	///   // initialize the CDK
	///
	///   // at some point in your code
	///   let msg : MyMessage = {
	///     some_field: "Hello, World!";
	///   };
	///
	///   IcWebSocketCdk.ws_send(ws_state, client_principal, to_candid(msg));
	/// }
	/// ```
	public func ws_send(ws_state : IcWebSocketState, client_principal : ClientPrincipal, msg_bytes : Blob) : async CanisterWsSendResult {
		_ws_send(ws_state, client_principal, msg_bytes, false);
	};

	func send_service_message_to_client(ws_state : IcWebSocketState, client_key : ClientKey, message : WebsocketServiceMessageContent) : Result<(), Text> {
		let message_bytes = encode_websocket_service_message_content(message);
		_ws_send(ws_state, client_key.client_principal, message_bytes, true);
	};

	/// Parameters for the IC WebSocket CDK initialization.
	///
	/// Arguments:
	///
	/// - `init_handlers`: Handlers initialized by the canister and triggered by the CDK.
	/// - `init_max_number_of_returned_messages`: Maximum number of returned messages. Defaults to `10` if null.
	/// - `init_send_ack_interval_ms`: Send ack interval in milliseconds. Defaults to `60_000` (60 seconds) if null.
	/// - `init_keep_alive_timeout_ms`: Keep alive timeout in milliseconds. Defaults to `10_000` (10 seconds) if null.
	public class WsInitParams(
		init_handlers : WsHandlers,
		init_max_number_of_returned_messages : ?Nat,
		init_send_ack_interval_ms : ?Nat64,
		init_keep_alive_timeout_ms : ?Nat64,
	) {
		/// The callback handlers for the WebSocket.
		public var handlers : WsHandlers = init_handlers;
		/// The maximum number of messages to be returned in a polling iteration.
		/// Defaults to `10`.
		public var max_number_of_returned_messages : Nat = switch (init_max_number_of_returned_messages) {
			case (?value) { value };
			case (null) { DEFAULT_MAX_NUMBER_OF_RETURNED_MESSAGES };
		};
		/// The interval at which to send an acknowledgement message to the client,
		/// so that the client knows that all the messages it sent have been received by the canister (in milliseconds).
		///
		/// Must be greater than `keep_alive_timeout_ms`.
		///
		/// Defaults to `60_000` (60 seconds).
		public var send_ack_interval_ms : Nat64 = switch (init_send_ack_interval_ms) {
			case (?value) { value };
			case (null) { DEFAULT_SEND_ACK_INTERVAL_MS };
		};
		/// The delay to wait for the client to send a keep alive after receiving an acknowledgement (in milliseconds).
		///
		/// Must be lower than `send_ack_interval_ms`.
		///
		/// Defaults to `10_000` (10 seconds).
		public var keep_alive_timeout_ms : Nat64 = switch (init_keep_alive_timeout_ms) {
			case (?value) { value };
			case (null) { DEFAULT_CLIENT_KEEP_ALIVE_TIMEOUT_MS };
		};

		public func get_handlers() : WsHandlers {
			return handlers;
		};

		/// Checks the validity of the timer parameters.
		/// `send_ack_interval_ms` must be greater than `keep_alive_timeout_ms`.
		///
		/// # Traps
		/// If `send_ack_interval_ms` < `keep_alive_timeout_ms`.
		public func check_validity() {
			if (keep_alive_timeout_ms > send_ack_interval_ms) {
				Debug.trap("send_ack_interval_ms must be greater than keep_alive_timeout_ms");
			};
		};
	};

	/// The IC WebSocket instance.
	///
	/// # Traps
	/// If the parameters are invalid. See [`WsInitParams::check_validity`] for more details.
	public class IcWebSocket(init_ws_state : IcWebSocketState, params : WsInitParams) {
		/// The state of the IC WebSocket.
		private var WS_STATE : IcWebSocketState = init_ws_state;
		/// The callback handlers for the WebSocket.
		private var HANDLERS : WsHandlers = params.get_handlers();

		// the equivalent of the [init] function for the Rust CDK
		do {
			// check if the parameters are valid
			params.check_validity();

			// reset initial timers
			WS_STATE.reset_timers();

			// schedule a timer that will send an acknowledgement message to clients
			WS_STATE.schedule_send_ack_to_clients(params.send_ack_interval_ms, params.keep_alive_timeout_ms, HANDLERS);
		};

		/// Resets the internal state of the IC WebSocket CDK.
		///
		/// **Note:** You should only call this function in tests.
		public func wipe() : async () {
			await WS_STATE.reset_internal_state(HANDLERS);

			Logger.custom_print("Internal state has been wiped!");
		};

		/// Handles the WS connection open event received from the WS Gateway
		///
		/// WS Gateway relays the first message sent by the client together with its signature
		/// to prove that the first message is actually coming from the same client that registered its public key
		/// beforehand by calling the [ws_register] method.
		public func ws_open(caller : Principal, args : CanisterWsOpenArguments) : async CanisterWsOpenResult {
			// anonymous clients cannot open a connection
			if (Principal.isAnonymous(caller)) {
				return #Err("anonymous principal cannot open a connection");
			};

			// avoid gateway opening a connection for its own principal
			if (WS_STATE.is_registered_gateway(caller)) {
				return #Err("caller is the registered gateway which can't open a connection for itself");
			};

			let client_key : ClientKey = {
				client_principal = caller;
				client_nonce = args.client_nonce;
			};
			// check if client is not registered yet
			if (WS_STATE.is_client_registered(client_key)) {
				return #Err("client with key " # clientKeyToText(client_key) # " already has an open connection");
			};

			// initialize client maps
			let new_client = RegisteredClient(args.gateway_principal);
			WS_STATE.add_client(client_key, new_client);

			let open_message : CanisterOpenMessageContent = {
				client_key;
			};
			let message : WebsocketServiceMessageContent = #OpenMessage(open_message);
			switch (send_service_message_to_client(WS_STATE, client_key, message)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (#Ok(_)) {
					// do nothing
				};
			};

			await HANDLERS.call_on_open({
				client_principal = client_key.client_principal;
			});

			#Ok;
		};

		/// Handles the WS connection close event received from the WS Gateway.
		public func ws_close(caller : Principal, args : CanisterWsCloseArguments) : async CanisterWsCloseResult {
			switch (WS_STATE.check_is_registered_gateway(caller)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (_) {
					// do nothing
				};
			};

			switch (WS_STATE.check_registered_client(args.client_key)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (_) {
					// do nothing
				};
			};

			await WS_STATE.remove_client(args.client_key, HANDLERS);

			#Ok;
		};

		/// Handles the WS messages received either directly from the client or relayed by the WS Gateway.
		///
		/// The second argument is only needed to expose the type of the message on the canister Candid interface and get automatic types generation on the client side.
		/// This way, on the client you have the same types and you don't have to care about serializing and deserializing the messages sent through IC WebSocket.
		///
		/// # Example
		/// ```motoko
		/// import IcWebSocketCdk "mo:ic-websocket-cdk";
		///
		/// actor MyCanister {
		///   // ...
		///
		///   type MyMessage = {
		///     some_field: Text;
		///   };
		///
		///   // declare also the other methods: ws_open, ws_close, ws_get_messages
		///
		///   public shared ({ caller }) func ws_message(args : IcWebSocketCdk.CanisterWsMessageArguments, msg_type : ?MyMessage) : async IcWebSocketCdk.CanisterWsMessageResult {
		///     await ws.ws_message(caller, args, msg_type);
		///   };
		///
		///   // ...
		/// }
		/// ```
		public func ws_message(caller : Principal, args : CanisterWsMessageArguments, _msg_type : ?Any) : async CanisterWsMessageResult {
			// check if client registered its principal by calling ws_open
			let registered_client_key = switch (WS_STATE.get_client_key_from_principal(caller)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (#Ok(client_key)) {
					client_key;
				};
			};

			let {
				client_key;
				sequence_num;
				timestamp;
				is_service_message;
				content;
			} = args.msg;

			// check if the client key is correct
			if (not areClientKeysEqual(registered_client_key, client_key)) {
				return #Err("client with principal " #Principal.toText(caller) # " has a different key than the one used in the message");
			};

			let expected_sequence_num = switch (WS_STATE.get_expected_incoming_message_from_client_num(client_key)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (#Ok(sequence_num)) {
					sequence_num;
				};
			};

			// check if the incoming message has the expected sequence number
			if (sequence_num != expected_sequence_num) {
				await WS_STATE.remove_client(client_key, HANDLERS);
				return #Err(
					"incoming client's message does not have the expected sequence number. Expected: " #
					Nat64.toText(expected_sequence_num)
					# ", actual: " #
					Nat64.toText(sequence_num)
					# ". Client removed."
				);
			};
			// increase the expected sequence number by 1
			switch (WS_STATE.increment_expected_incoming_message_from_client_num(client_key)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (_) {
					// do nothing
				};
			};

			if (is_service_message) {
				return await handle_received_service_message(client_key, content);
			};

			await HANDLERS.call_on_message({
				client_principal = client_key.client_principal;
				message = content;
			});

			#Ok;
		};

		/// Returns messages to the WS Gateway in response of a polling iteration.
		public func ws_get_messages(caller : Principal, args : CanisterWsGetMessagesArguments) : CanisterWsGetMessagesResult {
			// check if the caller of this method is the WS Gateway that has been set during the initialization of the SDK
			switch (WS_STATE.check_is_registered_gateway(caller)) {
				case (#Err(err)) {
					#Err(err);
				};
				case (_) {
					WS_STATE.get_cert_messages(caller, args.nonce, params.max_number_of_returned_messages);
				};
			};
		};

		/// Sends a message to the client. See [IcWebSocketCdk.ws_send] function for reference.
		public func send(client_principal : ClientPrincipal, msg_bytes : Blob) : async CanisterWsSendResult {
			await ws_send(WS_STATE, client_principal, msg_bytes);
		};

		func handle_received_service_message(client_key : ClientKey, content : Blob) : async Result<(), Text> {
			let message_content = switch (decode_websocket_service_message_content(content)) {
				case (#Err(err)) {
					return #Err(err);
				};
				case (#Ok(message_content)) {
					message_content;
				};
			};

			switch (message_content) {
				case (#KeepAliveMessage(keep_alive_message)) {
					handle_keep_alive_client_message(client_key, keep_alive_message);
					#Ok;
				};
				case (_) {
					return #Err("Invalid received service message");
				};
			};
		};

		func handle_keep_alive_client_message(client_key : ClientKey, _keep_alive_message : ClientKeepAliveMessageContent) {
			// TODO: delete messages from the queue that have been acknowledged by the client

			WS_STATE.update_last_keep_alive_timestamp_for_client(client_key);
		};
	};
};

import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import List "mo:base/List";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Option "mo:base/Option";

import C "Combinators";
import L "List";
import P "Parser";

module JSON {
    public type JSON = {
        #Number : Int;
        #Float : Float;
        #String : Text;
        #Array : [JSON];
        #Object : [(Text, JSON)];
        #Boolean : Bool;
        #Null;
    };

    public func strip(text : Text, start : Char, end : Char) : (Text) 
    {
        var placeholder = text;
        var str = placeholder;
        str := Option.get(Text.stripStart(str, #char start), placeholder);
        placeholder := str;
        str := Option.get(Text.stripEnd(str, #char end), placeholder);
        return str;
    };
    public func show(json : JSON) : Text = switch (json) {
        case (#Number(v)) { Int.toText(v); };
        case (#Float(v)) { Float.format(#fix(2), v); };
        case (#String(v)) { "\"" # v # "\""; };
        case (#Array(v)) {
            var s = "[";
            for (i in v.vals()) {
                if (s != "[") { s #= ", "; };
                s #= show(i);
            };
            s # "]";
        };
        case (#Object(v)) {
            var s = "{";
            for ((k, v) in v.vals()) {
                if (s != "{") { s #= ", "; };
                s #= "\"" # k # "\"" # ": " # show(v);
            };
            s # "}";
        };
        case (#Boolean(v)) {
            if (v) { return "true"; };
            "false";
        };
        case (#Null) { "null"; };
    };

    public func get_key(data : Text, _key : Text) : Text {
        var j : ?JSON = JSON.parse(data);
        switch (JSON.parse(data)) {
        case (?j) {
            var t : Text = getKey(j, _key, false);
            return t;
        };
        case _ { return "not found" };
        };
    };

    public func get_unwrapped_key(data : Text, _key : Text) : (Text){
        return JSON.strip(get_key(data, _key),'{','}');
    };

    public func get_typed_array(json : Text, array_name : Text) : ([JSON.JSON]){
        let jsonArray = JSON.get_key(json, array_name);
        
        let unwrappedJsonArray = JSON.get_unwrapped_key(json, array_name);

        if(jsonArray == "not found") return [];

        return switch (JSON.parse(unwrappedJsonArray)){
            case(? parsedUnwrappedJsonArray){
                switch(parsedUnwrappedJsonArray){
                    case(#Array(array)){ return array; };
                    case (_){ []; };
                };
            };
            case (_){ []; };
        
        } 
    };

    public func get_element_by_field_value(json : Text, array_name : Text, field_to_inspect_name : Text, field_to_inspect_value : Text) : (Result.Result<Text, Text>){
        var strjson_arr : Text = get_key(json, array_name);
        strjson_arr := JSON.strip(strjson_arr,'{','}');
        switch (JSON.parse(strjson_arr)){
            case (?j){
                switch (j){
                    case (#Array(v)){
                        for(i in v.vals()){
                            var tt : Text = show(i);
                            var _itemId : Text = JSON.strip(get_key(tt, field_to_inspect_name),'{','}');
                            // return #err("Test Error: field name " # field_to_inspect_name # ", field value " # field_to_inspect_value # " == "#_itemId);
                            if(_itemId == field_to_inspect_value){
                                return #ok(show(i));
                            }
                        };
                        return #err("key and value not found");
                    };
                    case _ {return #err("entered json is not an array");};
                };
            };
            case _ {
                return #err("json not valid");
            };
        };
    };
    
    public func update_key(json : JSON, _key : Text, _val : Text) : Text = switch (json) {
        case (#Number(v)) { Int.toText(v); };
        case (#Float(v)) { Float.format(#fix(2), v); };
        case (#String(v)) { "\"" # v # "\""; };
        case (#Array(v)) {
            var s = "[";
            for (i in v.vals()) {
                if (s != "[") { s #= ", "; };
                s #= show(i);
            };
            s # "]";
        };
        case (#Object(v)) {
            var s = "{";
            for ((k, v) in v.vals()) {
                if(k == _key){
                    if (s != "{") { s #= ", "; };
                    s #= "\"" # k # "\"" # ": " # _val;
                } else {
                    if (s != "{") { s #= ", "; };
                    s #= "\"" # k # "\"" # ": " # update_key(v, _key, _val);
                }
            };
            s # "}";
        };
        case (#Boolean(v)) {
            if (v) { return "true"; };
            "false";
        };
        case (#Null) { "null"; };
    };

    private func character() : P.Parser<Char, Char> = C.oneOf([
        C.sat<Char>(func (c : Char) : Bool {
            c != Char.fromNat32(0x22) and c != '\\';
        }),
        C.right(
            C.Character.char('\\'),
            C.map(
                C.Character.oneOf([
                    Char.fromNat32(0x22), '\\', '/', 'b', 'f', 'n', 'r', 't',
                    // TODO: u hex{4}
                ]),
                func (c : Char) : Char {
                    switch (c) {
                        case ('b') { Char.fromNat32(0x08); };
                        case ('f') { Char.fromNat32(0x0C); };
                        case ('n') { Char.fromNat32(0x0A); };
                        case ('r') { Char.fromNat32(0x0D); };
                        case ('t') { Char.fromNat32(0x09); };
                        case (_) { c; };
                    };
                }
            )
        )
    ]);

    private func ignoreSpace<A>(parserA : P.Parser<Char, A>) : P.Parser<Char, A> = C.right(
        C.many(C.Character.space()), parserA
    );

    public func parse(t : Text) : ?JSON = parseValues(L.fromText(t));

    public func parseRaw(data : [Char]) : ?JSON = parseValues(L.fromIter(data.vals()));

    public func parseRawASCII(data : [Nat8]) : ?JSON = parseValues(nat8sToCharList(data.vals()));

    private func parseValues(l : List.List<Char>) : ?JSON = switch (valueParser()(l)) {
        case (null) { null; };
        case (? (x, xs)) {
            switch (xs) {
                case (null) { ?x; };
                case (_) { null;  };
            };
        };
    };

    private func nat8sToCharList(i : Iter.Iter<Nat8>) : List.List<Char> = switch (i.next()) {
        case (null) { null; };
        case (? v)  { ?(Char.fromNat32(Nat32.fromNat(Nat8.toNat(v))), nat8sToCharList(i)); };
    };

    private func valueParser() : P.Parser<Char, JSON> = C.bracket(
        C.many(C.Character.space()),
        C.oneOf([
            objectParser(),
            arrayParser(),
            stringParser(),
            floatParser(),
            numberParser(),
            boolParser(),
            nullParser()
        ]),
        C.many(C.Character.space())
    );

    private func objectParser() : P.Parser<Char, JSON> = C.map(
        C.bracket(
            C.Character.char('{'),
            ignoreSpace(
                C.sepBy(
                    C.seq(
                        C.left(
                            ignoreSpace(string()),
                            ignoreSpace(C.Character.char(':'))
                        ),
                        P.delay(valueParser)
                    ),
                    C.Character.char(',')
                )
            ),
            C.Character.char('}')
        ),
        func (t : List.List<(Text, JSON)>) : JSON {
            #Object(List.toArray(t));
        }
    );

    private func arrayParser() : P.Parser<Char, JSON> = C.map(
        C.bracket(
            C.Character.char('['),
            ignoreSpace(
                C.sepBy(
                    P.delay(valueParser),
                    C.Character.char(',')
                ),
            ),
            C.Character.char(']')
        ),
        func (t : List.List<JSON>) : JSON {
            #Array(List.toArray(t));
        }
    );

    private func string() : P.Parser<Char, Text> = C.map(
        C.bracket(
            C.Character.char(Char.fromNat32(0x22)),
            C.many(character()),
            C.Character.char(Char.fromNat32(0x22))
        ),
        func (t : List.List<Char>) : Text {
            Text.fromIter(L.toIter(t));
        }
    );

    private func stringParser() : P.Parser<Char, JSON> = C.map(
        C.map(
            C.bracket(
                C.Character.char(Char.fromNat32(0x22)), 
                C.many(character()), 
                C.Character.char(Char.fromNat32(0x22))
            ),
            func (t : List.List<Char>) : Text {
                Text.fromIter(L.toIter(t));
            },
        ),
        func (t : Text) : JSON {
            #String(t);
        }
    );

    private func floatParser() : P.Parser<Char, JSON> = C.map(
        C.oneOf([
            parseFloatWithExp(),
            parseFloat(),
        ]),
        func(n : Float) : JSON = #Float(n),
    );

    private func parseFloat() : P.Parser<Char, Float> {
        C.map(
            C.seq<Char, Int, List.List<Char>>(
                C.Int.int(),
                C.right(
                    C.Character.char('.'),
                    C.many1(C.Character.digit()),
                ),
            ),
            func((n, decimal_list) : (Int, List.List<Char>)) : Float {
                let isNegative = n < 0;
                var num = n;
                var n_of_decimals : Float = 0;

                for (char in Iter.fromList(decimal_list)) {
                    let digit = Nat32.toNat(
                        Char.toNat32(char) - Char.toNat32('0')
                    );

                    if (isNegative) {
                        num := num * 10 - digit;
                    } else {
                        num := num * 10 + digit;
                    };

                    n_of_decimals += 1;
                };

                let float = Float.fromInt(num) / (10 ** n_of_decimals);
            },
        );
    };

    private func parseFloatWithExp() : P.Parser<Char, Float> = C.map(
        C.seq(
            C.oneOf([
                parseFloat(),
                C.map(
                    C.Int.int(),
                    func(i : Int) : Float = Float.fromInt(i),
                ),
            ]),
            C.right(
                C.oneOf([C.String.string("e"), C.String.string("E")]),
                C.Int.int(),
            ),
        ),
        func((n, exponent) : (Float, Int)) : Float {
            let exp = Float.fromInt(exponent);
            let isNegative = exp < 0;

            if (isNegative) {
                return n / (10 ** -exp);
            };

            n * (10 ** exp);
        },
    );

    private func numberParser() : P.Parser<Char, JSON> = C.map(
        C.Int.int(),
        func (i : Int) : JSON {
            #Number(i);
        }
    );

    private func boolParser() : P.Parser<Char, JSON> = C.map(
        C.choose(
            C.String.string("true"),
            C.String.string("false")
        ),
        func (t : Text) : JSON {
            if (t == "true") return #Boolean(true);
            #Boolean(false);
        }
    );

    private func nullParser() : P.Parser<Char, JSON> = C.map(
        C.String.string("null"),
        func (_ : Text) : JSON {
            #Null;
        }
    );

    private func getKey(json : JSON, _key : Text, found : Bool) : Text = switch (json) {
        case (#Number(v)) { Int.toText(v); };
        case (#Float(v)) { Float.format(#fix(2), v); };
        case (#String(v)) { 
            return "" # v # "";
         };
        case (#Array(v)) {
            var s = "[";
            for (i in v.vals()) {
                if (s != "[") { s #= ", "; };
                s #= show(i);
            };
            s # "]";
        };
        case (#Object(v)) {
            var s = "{";
            for ((k, v) in v.vals()) {
                if(k == _key and found == false){
                    s #= getKey(v, _key, true);
                } else if (found == true){
                    if (s != "{") { s #= ", "; };
                    s #= "\"" # k # "\"" # ": " # getKey(v, _key, true);
                }
                //here this need fixes
            };
            s # "}";
        };
        case (#Boolean(v)) {
            if (v) { return "true"; };
            "false";
        };
        case (#Null) { "null"; };
    };

};
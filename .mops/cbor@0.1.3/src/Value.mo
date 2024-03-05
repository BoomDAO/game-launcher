import FloatX "mo:xtended-numbers/FloatX";

module {
  public type Value = {
    #majorType0: Nat64; // 0 -> 2^64 - 1
    #majorType1: Int; // -2^64 -> -1 ((-1 * Value) - 1)
    #majorType2 : [Nat8];
    #majorType3: Text;
    #majorType4: [Value];
    #majorType5: [(Value, Value)];
    #majorType6: {
      tag: Nat64;
      value: Value;
    };
    #majorType7: {
      #integer: Nat8;
      #bool: Bool;
      #_null;
      #_undefined;
      #float: FloatX.FloatX;
      #_break;
    };
  };
}
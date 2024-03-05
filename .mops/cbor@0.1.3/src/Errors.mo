import FloatX "mo:xtended-numbers/FloatX";

module {
  public type DecodingError = {
    #unexpectedEndOfBytes;
    #unexpectedBreak;
    #invalid: Text;
  };

  public type EncodingError = {
    #invalidValue: Text;
  };
}
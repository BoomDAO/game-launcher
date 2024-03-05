import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import NatX "./NatX";

module {

  public type FloatPrecision = { #f16; #f32; #f64 };

  public type FloatX = {
    precision : FloatPrecision;
    isNegative : Bool;
    exponent : ?Int;
    mantissa : Nat;
  };

  public func nearlyEqual(a : Float, b : Float, relativeTolerance : Float, absoluteTolerance : Float) : Bool {
    let maxAbsoluteValue : Float = Float.max(Float.abs(a), Float.abs(b));
    Float.abs(a -b) <= Float.max(relativeTolerance * maxAbsoluteValue, absoluteTolerance);
  };

  public func fromFloat(float : Float, precision : FloatPrecision) : FloatX {
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(precision);
    if (float == 0.0) {
      return {
        precision = precision;
        isNegative = false;
        exponent = null;
        mantissa = 0;
      };
    };
    let isNegative = float < 0;

    // maxMantissa = 2 ^ mantissaBitLength
    // e = 2^exponent * (x + mantissa/maxMantissa)
    // float = sign * e
    // where x is 1 if exponent > 0 else 0
    // where sign is 1 if positive else -1

    // Normal number are numbers that are represented by 2^minExponent -> 2^maxExponent - 1
    // Sub normal numbers are numbers represented by 2^minExponent * 1/maxMantissa -> 2^minExponent * (maxMantissa - 1)/maxMantissa
    let isNormalNumber : Bool = Float.abs(float) >= bitInfo.smallestNormalNumber;
    let (exponent : ?Int, x : Int) = if (isNormalNumber) {
      // If is normal number then x is 1
      // e is 2^exponent + (number less than 2)
      // so if you get the log2(e), truncate the remainder, it will represent the exponent
      let e : Int = Float.toInt(Float.floor(Float.log(Float.abs(float)) / Float.log(2)));
      (?e, 1);
    } else {
      // If smaller than 2^minExponent then x is 0
      // e is 2^exponent + (number less than 1)
      // exponent is min value
      var a = null; // TODO bug where this cant be a const
      (a, 0);
    };

    // m = (|float|/2^exponent) - x
    // mantissa = m * maxMantissa
    // The m is the % of the exponent as the remainder between exponent and real value
    let exp = switch (exponent) {
      case (null) bitInfo.minExponent; // If null, its subnormal. use min exponent here
      case (?e) e;
    };
    let m : Float = (Float.abs(float) / calculateExponent(2, Float.fromInt(exp)) - Float.fromInt(x));
    // Mantissa represent how many offsets there are between the exponent and the value
    let mantissa : Nat = Int.abs(Float.toInt(Float.nearest(m * Float.fromInt(bitInfo.maxMantissaDenomiator))));

    {
      precision = precision;
      isNegative = isNegative;
      exponent = exponent;
      mantissa = mantissa;
    };
  };

  public func toFloat(fX : FloatX) : Float {
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(fX.precision);

    // e = 2^exponent * (x + mantissa/maxMantissa)
    // float = sign * e
    // where x is 1 if exponent > 0 else 0
    // where sign is 1 if positive else -1

    let sign = if (fX.isNegative) -1.0 else 1.0;
    let (exponent : Int, x : Nat) = switch (fX.exponent) {
      case (null)(-14, 0); // If null, its subnormal. use min exponent here
      case (?exponent)(exponent, 1);
    };
    let expValue : Float = calculateExponent(2, Float.fromInt(exponent));
    sign * expValue * (Float.fromInt(x) + Float.fromInt(fX.mantissa) / Float.fromInt(bitInfo.maxMantissaDenomiator));
  };

  public func encode(buffer : Buffer.Buffer<Nat8>, value : FloatX, encoding : { #lsb; #msb }) {
    var bits : Nat64 = 0;
    if (value.isNegative) {
      bits |= 0x01;
    };
    let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(value.precision);
    bits <<= Nat64.fromNat(bitInfo.exponentBitLength);

    let exponentBits : Nat64 = switch (value.exponent) {
      case (null) 0;
      case (?exponent) Int64.toNat64(Int64.fromInt(exponent + bitInfo.maxExponent));
    };
    bits |= exponentBits;
    bits <<= Nat64.fromNat(bitInfo.mantissaBitLength);
    let mantissaBits : Nat64 = Nat64.fromNat(value.mantissa);
    bits |= mantissaBits;

    switch (value.precision) {
      case (#f16) {
        let nat16 = NatX.from64To16(bits);
        NatX.encodeNat16(buffer, nat16, encoding);
      };
      case (#f32) {
        let nat32 = NatX.from64To32(bits);
        NatX.encodeNat32(buffer, nat32, encoding);
      };
      case (#f64) {
        NatX.encodeNat64(buffer, bits, encoding);
      };
    };
  };

  public func decode(bytes : Iter.Iter<Nat8>, precision : { #f16; #f32; #f64 }, encoding : { #lsb; #msb }) : ?FloatX {
    do ? {
      let bits : Nat64 = switch (precision) {
        case (#f16) NatX.from16To64(NatX.decodeNat16(bytes, encoding)!);
        case (#f32) NatX.from32To64(NatX.decodeNat32(bytes, encoding)!);
        case (#f64) NatX.decodeNat64(bytes, encoding)!;
      };
      let bitInfo : PrecisionBitInfo = getPrecisionBitInfo(precision);
      if (bits == 0) {
        return ?{
          precision = precision;
          isNegative = false;
          exponent = null;
          mantissa = 0;
        };
      };
      let (exponentBitLength : Nat64, mantissaBitLength : Nat64) = (Nat64.fromNat(bitInfo.exponentBitLength), Nat64.fromNat(bitInfo.mantissaBitLength));
      // Bitshift to get mantissa, exponent and sign bits
      let mantissa : Nat = Nat64.toNat(bits & (2 ** mantissaBitLength - 1));
      // Extract out exponent bits with bitshift and mask
      let exponentBits : Nat64 = (bits >> mantissaBitLength) & (2 ** exponentBitLength - 1);
      let exponent : ?Int = if (exponentBits == 0) {
        // If not bits are set, then it is sub normal
        null;
      } else {
        // Get real exponent from the exponent bits
        ?(Nat64.toNat(exponentBits) - bitInfo.maxExponent);
      };
      let signBits : Nat64 = (bits >> (mantissaBitLength + exponentBitLength)) & 0x01;

      // Make negative if sign bit is 1
      let isNegative : Bool = signBits == 1;
      {
        precision = precision;
        isNegative = isNegative;
        exponent = exponent;
        mantissa = mantissa;
      };
    };
  };

  private func calculateExponent(value : Float, exponent : Float) : Float {
    if (exponent < 0) {
      // Negative exponents arent allowed??
      // Have to do inverse of the exponent value
      1 / value ** (-1 * exponent);
    } else {
      value ** exponent;
    };
  };

  private type PrecisionBitInfo = {
    exponentBitLength : Nat;
    mantissaBitLength : Nat;
    maxMantissaDenomiator : Nat;
    minExponent : Int;
    maxExponent : Int;
    smallestNormalNumber : Float;
  };

  private func getPrecisionBitInfo(precision : FloatPrecision) : PrecisionBitInfo {
    let (exponentBitLength : Nat, mantissaBitLength : Nat) = switch (precision) {
      case (#f16)(5, 10);
      case (#f32)(8, 23);
      case (#f64)(11, 52);
    };
    let maxExponent : Int = 2 ** (exponentBitLength - 1) - 1;
    let minExponent : Int = -1 * (maxExponent - 1);

    let smallestNormalNumber : Float = calculateExponent(2, Float.fromInt(minExponent));
    {
      exponentBitLength = exponentBitLength;
      mantissaBitLength = mantissaBitLength;
      minExponent = minExponent;
      maxExponent = maxExponent;
      maxMantissaDenomiator = 2 ** mantissaBitLength;
      smallestNormalNumber = smallestNormalNumber;
    };
  };

};

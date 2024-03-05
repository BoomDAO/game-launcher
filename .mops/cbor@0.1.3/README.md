## Funding

This library was originally incentivized by [ICDevs](https://ICDevs.org). You
can view more about the bounty on the
[forum](https://forum.dfinity.org/t/icdevs-org-bounty-18-cbor-and-candid-motoko-parser-3-000/11398)
or [website](https://icdevs.org/bounties/2022/02/22/CBOR-and-Candid-Motoko-Parser.html). The
bounty was funded by The ICDevs.org commuity and the award paid to
@Gekctek. If you use this library and gain value from it, please consider
a [donation](https://icdevs.org/donations.html) to ICDevs.

# Overview

This is a library that is written in Motoko that enables the encoding and decoding of CBOR between bytes and a CBOR variant type

# Package

### MOPS

```
mops install cbor
```

To setup MOPS package manage, follow the instructions from the [MOPS Site](https://j4mwm-bqaaa-aaaam-qajbq-cai.ic0.app/)

### Vessel

Currently there is no official package but there is a manual process:

1. Add the following to the `additions` list in the `package-set.dhall`

```
{
    name = "cbor"
    , version = "{{Version}}"
    , repo = "https://github.com/gekctek/motoko_cbor"
    , dependencies = [] : List Text
}
```

Where `{{Version}}` should be replaced with the latest release from https://github.com/Gekctek/motoko_cbor/releases/tag/v0.0.1

2. Add `cbor` as a value in the dependencies list
3. Run `./build.sh` which runs the vessel command to install the package

# Usage

### Cbor Bytes -> Cbor Object

```
import Types "mo:cbor/Types";
import CborDecoder "mo:cbor/CborDecoder";

let bytes: [Nat8] = [0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff];
let cbor: Types.CborValue = switch(CborDecoder.decodeBytes(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};
```

### Cbor Object -> Cbor Bytes

```
import Types "mo:cbor/Types";
import CborEncoder "mo:cbor/CborEncoder";

let bytes: Types.CborValue = #majorType5([
    (#majorType3("Fun"), #majorType7(#bool(true))),
    (#majorType3("Amt"), #majorType1(-2))
]);
let bytes: [Nat8] = switch(CborEncoder.encode(bytes)) {
    case (#err(e)) ...;
    case (#ok(c)) c;
};

```

### Custom Type -> Cbor Bytes

_Not Yet Implemented_
use `to_candid(...)`. See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#candid-serialization

### Cbor Bytes -> Custom Type

_Not Yet Implemented_
use `from_candid(...)`. See https://internetcomputer.org/docs/current/developer-docs/build/cdks/motoko-dfinity/language-manual#candid-serialization

# API

## Decoder.mo

`decode(blob: Blob) : Result.Result<Value.Value, Errors.DecodingError>`

Decodes a blob into a cbor value variant

## Encoder.mo

`encode(value: Value.Value) : Result.Result<[Nat8], Errors.EncodingError>`

Encodes a cbor value into a byte array

`encodeToBuffer(buffer: Buffer.Buffer<Nat8>, value: Value.Value) : Result.Result<(), Errors.EncodingError>`

Encodes a cbor value into the supplied byte buffer

# FloatX: Half(16), Single(32), Double(64)

Due to the lack of float functionality (`float <-> bytes`, `half`, `single`) and external reference was used for these. `xtended-numbers` in vessel or `github.com/gekctek/motoko_numbers`

# Library Devlopment:

## First time setup

To build the library, the `Vessel` library must be installed. It is used to pull down packages and locate the compiler for building.

https://github.com/dfinity/vessel

## Building

To build, run the `./build.sh` file. It will output wasm files to the `./build` directory

## Testing

To run tests, use the `./test.sh` file.
The entry point for all tests is `test/Tests.mo` file
It will compile the tests to a wasm file and then that file will be executed.
Currently there are no testing frameworks and testing will stop at the first broken test. It will then output the error to the console

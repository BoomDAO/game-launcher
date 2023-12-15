# ic-certification

This Motoko library provides functionality around “Certification”, in particular

 * A labeled tree data sturcture with merkelization (`MerkleTree`) and the ability to
   generate witnesses according to Internet Computer Interface Specification.
 * Support for the “Canister Signature scheme” that builds on top of that.
 * Utilities related to the “Implementation-independent hash” that is used,
   among other things, for signing HTTP requests to the Internet Computer

See <https://nomeata.github.io/ic-certification/> for the docuemntation of the
current development version.

The `demo/` directory contains a commented  canister demonstrating these features; it is also live
at <https://wpsi7-7aaaa-aaaai-acpzq-cai.ic0.app/>.


## Installation

Using [MOPS](https://mops.one/ic-certification):

    mops add ic-certification

or using [vessel](https://github.com/dfinity/vessel).

See `Developemnt.md` for development and testing information.

## License

This library is distributed under the terms of the Apache License (Version 2.0). See LICENSE for details.

## Funding

This library was initially incentivized by [ICDevs](https://icdevs.org/). You can view more about
the bounty on the
[forum](https://forum.dfinity.org/t/open-icdev-org-bounty-36-signing-tree-and-der-encoding-motoko-10-000/17889)
or [website](https://icdevs.org/bounties/2023/01/09/36-Signing-Tree-and-DER-Encoding.html).
The bounty was funded by The ICDevs.org community and the DFINITY
Foundation and the award was paid to TODO.
If you use this library and gain value from it, please consider a donation to ICDevs.

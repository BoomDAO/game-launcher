export IC_VERSION=072b2a6586c409efa88f2244d658307ff3a645d8
curl -o ic-icrc1-ledger.wasm.gz https://download.dfinity.systems/ic/${IC_VERSION}/canisters/ic-icrc1-ledger.wasm.gz
curl -o ledger.did https://raw.githubusercontent.com/dfinity/ic/${IC_VERSION}/rs/rosetta-api/icrc1/ledger/ledger.did
gunzip ic-icrc1-ledger.wasm.gz
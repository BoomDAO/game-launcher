export IC_VERSION=master
curl -o src/game_launcher_backend/launchpad/icrc/ic-icrc1-ledger.wasm.gz https://raw.githubusercontent.com/dfinity/ic/${IC_VERSION}/rs/rosetta-api/icrc1/wasm/ic-icrc1-archive.wasm.gz
curl -o src/game_launcher_backend/launchpad/icrc/ledger.did https://raw.githubusercontent.com/dfinity/ic/${IC_VERSION}/rs/rosetta-api/icrc1/ledger/ledger.did
gunzip ./src/game_launcher_backend/launchpad/icrc/ic-icrc1-ledger.wasm.gz 
export IC_COMMIT="43f31c0a1b0d9f9ecbc4e2e5f142c56c7d9b0c7b"
curl -o src/game_launcher_backend/launchpad/icrc/ic-icrc1-ledger.wasm.gz https://download.dfinity.systems/ic/$IC_COMMIT/canisters/ic-icrc1-ledger.wasm.gz
curl -o src/game_launcher_backend/launchpad/icrc/ledger.did https://raw.githubusercontent.com/dfinity/ic/$IC_COMMIT/rs/rosetta-api/icrc1/ledger/ledger.did 
gunzip ./src/game_launcher_backend/launchpad/icrc/ic-icrc1-ledger.wasm.gz 
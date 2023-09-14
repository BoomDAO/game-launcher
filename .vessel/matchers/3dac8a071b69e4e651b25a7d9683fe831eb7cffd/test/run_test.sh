#!/usr/bin/env bash

set -eo pipefail


echo "Checking Canister.mo compiles"
$(vessel bin)/moc $(vessel sources) ../src/Canister.mo

$(vessel bin)/moc $(vessel sources) -wasi-system-api Test.mo
wasmtime Test.wasm

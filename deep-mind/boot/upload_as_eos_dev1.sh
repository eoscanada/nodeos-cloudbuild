#!/usr/bin/env bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function main() {
    cd $ROOT

    if [[ ! -f "eos-2.x/genesis.json" ]]; then
        echo "File eos-2.x/genesis.json must exist, something fishy here"
        exit 1
    fi

    if [[ ! -f "eos-2.x/blocks/blocks.log" ]]; then
        echo "File eos-2.x/blocks/blocks.log must exist, have you executed 'run.sh' script?"
        exit 1
    fi

    echo "Uploading 'eos-2.x/genesis.json' and 'blocks/blocks.log' file to 'gs://dfuseio-global-seed-us/eos-dev1/'"
    gsutil cp eos-2.x/genesis.json gs://dfuseio-global-seed-us/eos-dev1/genesis.json
    echo ""

    gsutil cp eos-2.x/blocks/blocks.log gs://dfuseio-global-seed-us/eos-dev1/blocks.log
}

main $@


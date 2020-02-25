#!/bin/bash -e

mkdir -p /workspace/artifacts

function pickup() {
    # $1 contract name
    # $2 contract revision
    # $3 pushd to that place
    # $4 what to pickup
    mkdir -p /workspace/artifacts/$1/$2

    pushd $3
    cp -arv $4 /workspace/artifacts/$1/$2/
    popd
}

function injectabi() {
    ./ricardeos.py $1
}

# eosio.contracts

CONTRACTS_BRANCH=${CONTRACTS_BRANCH:-master}
CONTRACTS_REPO=${CONTRACTS_REPO:-https://github.com/eosio/eosio.contracts}
GOVERNANCE_BRANCH=${GOVERNANCE_BRANCH:-master}
GOVERNANCE_REPO=${GOVERNANCE_REPO:-https://github.com/eos-mainnet/governance}

git clone -b $CONTRACTS_BRANCH --depth 1 $CONTRACTS_REPO
git clone -b $GOVERNANCE_BRANCH --depth 1 $GOVERNANCE_REPO
cp ./governance/eosio.system/*.md ./eosio.contracts/eosio.system/abi
cp ./governance/eosio.token/*.md ./eosio.contracts/eosio.token/abi

pushd eosio.contracts
sed -i 's/^\(.*UnitTestsExternalProjec.*\)$/#\1/' CMakeLists.txt
./build.sh
popd

injectabi ./eosio.contracts/eosio.system/abi/eosio.system.abi
injectabi ./eosio.contracts/eosio.token/abi/eosio.token.abi

pickup eosio.system $CONTRACTS_BRANCH ./eosio.contracts/eosio.system bin
pickup eosio.sudo $CONTRACTS_BRANCH ./eosio.contracts/eosio.sudo bin
pickup eosio.msig $CONTRACTS_BRANCH ./eosio.contracts/eosio.msig bin
pickup eosio.token $CONTRACTS_BRANCH ./eosio.contracts/eosio.token bin


# eosio.forum

FORUM_BRANCH=${FORUM_BRANCH:-master}
FORUM_REPO=${FORUM_REPO:-https://github.com/eoscanada/eosio.forum}

git clone -b $FORUM_BRANCH --depth 1 $FORUM_REPO
pushd eosio.forum
cmake .
popd

pickup eosio.forum $FORUM_BRANCH eosio.forum forum.wasm
pickup eosio.forum $FORUM_BRANCH eosio.forum abi/forum.abi




pushd eosio.contracts && echo `git describe --always --long` > /workspace/artifacts/eosio.contracts.rev && popd

pushd governance && echo `git describe --always --long` > /workspace/artifacts/governance.rev && popd

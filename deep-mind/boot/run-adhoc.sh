#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

nodeos_pid=""
current_dir=`pwd`

function cleanup {
    if [[ $nodeos_pid != "" ]]; then
      echo "Closing nodeos process"
      kill -s TERM $nodeos_pid &> /dev/null || true
    fi

    cd $current_dir
    exit 0
}

function main() {
  eos_bin="$1"

  if [[ ! -f $eos_bin ]]; then
    echo "The 'nodeos' binary received does not exist, check first provided argument."
    exit 1
  fi

  # Trap exit signal and clean up
  trap cleanup EXIT

  pushd $ROOT &> /dev/null

  deep_mind_log_file="./deep-mind-adhoc.dmlog"
  nodeos_log_file="./nodeos.log"
  eosc_boot_log_file="./eosc-boot.log"

  rm -rf "$ROOT/blocks/" "$ROOT/state/"

  ($eos_bin --data-dir="$ROOT" --config-dir="$ROOT" --genesis-json="$ROOT/genesis.json" 1> $deep_mind_log_file 2> $nodeos_log_file) &
  nodeos_pid=$!

  echo "Booting $1 node with smart contracts ..."
  eosc boot bootseq.yaml --reuse-genesis --api-url http://localhost:9898 1> /dev/null
  mv output.log ${eosc_boot_log_file}
  popd 1> /dev/null

  echo "Booting completed, launching test cases..."

  export EOSC_GLOBAL_INSECURE_VAULT_PASSPHRASE=secure
  export EOSC_GLOBAL_API_URL=http://localhost:9898
  export EOSC_GLOBAL_VAULT_FILE="$ROOT/eosc-vault.json"

  # echo "Setting eosio.code permissions on contract accounts (Account for commit d8fa7c0, which shields from mis-used authority)"
  # eosc system updateauth battlefield1 active owner "$ROOT"/active_auth_battlefield1.yaml
  # eosc system updateauth battlefield3 active owner "$ROOT"/active_auth_battlefield3.yaml
  # eosc system updateauth notified2 active owner "$ROOT"/active_auth_notified2.yaml
  # sleep 0.6

  known_features=`curl -s "$EOSC_GLOBAL_API_URL/v1/producer/get_supported_protocol_features" | jq -cr '.[]'`

  echo ""
  echo "Available protocol features"
  echo $known_features | jq -r '. | "- \(.specification[].value) (Digest \(.feature_digest))"'

  echo ""
  echo "Activating protocol features"
  curl -s -X POST "$EOSC_GLOBAL_API_URL/v1/producer/schedule_protocol_feature_activations" -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}' > /dev/null
  eosc system setcontract eosio contracts/eosio.system-1.7.0-rc1.wasm contracts/eosio.system-1.7.0-rc1.abi
  sleep 1.8

  # This activates all known protocol features (RAM correction operations, WebAuthN keys, WTMSIG blocks, etc)
  echo ""
  echo "Activating all protocol features"
  for feature in `echo $known_features | jq -c . | grep -v "0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"`; do
    digest=`echo "$feature" | jq -cr .feature_digest`
    eosc tx create eosio activate "{\"feature_digest\":\"$digest\"}" -p eosio@active
  done

  # Activating all protocol features requires around 6 blocks to complete, so let's give 7 for a small buffer
  sleep 3.6

  echo "Installing smart contract..."
  eosc system setcontract battlefield3 ../battlefield/battlefield-with-handler.wasm ../battlefield/battlefield-with-handler.abi
  sleep 0.6

  eosc tx create battlefield3 kvbios '{"any":"eosio"}' -p battlefield3@active
  sleep 0.6

  eosc tx create battlefield3 kv1insert '{"any":"eosio"}' -p battlefield3@active
  sleep 0.6

  # echo -n "Activate protocol feature (WEBAUTHN_KEY)"
  # eosc tx create eosio activate '{"feature_digest":"4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2"}' -p eosio@active
  # sleep 1.2

  # echo ""
  # echo "Using eosio.bios contract temporarly to set producers"
  # eosc system setcontract eosio contracts/eosio.bios-1.5.2.wasm contracts/eosio.bios-1.5.2.abi
  # sleep 0.6


  # echo "Updating producers"
  # eosc tx create eosio setprods '{"schedule": [{"producer_name": "eosio2", "block_signing_key":"EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP"}]}' -p eosio@active
  # sleep 1.8

  # echo "Returning eosio contract to standard eosio.system contract"
  # eosc system setcontract eosio contracts/eosio.system-1.5.2.wasm contracts/eosio.system-1.5.2.abi
  # sleep 0.6

  # echo "Activating protocol features"
  # curl -s -X POST "$EOSC_GLOBAL_API_URL/v1/producer/schedule_protocol_feature_activations" -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}' > /dev/null
  # sleep 1.2

  # eosc system setcontract eosio contracts/eosio.system-1.7.0-rc1.wasm contracts/eosio.system-1.7.0-rc1.abi
  # sleep 0.6

  # echo ""
  # echo -n "Activate protocol feature (WEBAUTHN_KEY)"
  # eosc tx create eosio activate '{"feature_digest":"4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2"}' -p eosio@active
  # sleep 1.2

  # export WEBAUTHN_PUBLIC_KEY="PUB_WA_7qjMn38M4Q6s8wamMcakZSXLm4vDpHcLqcehnWKb8TJJUMzpEZNw41pTLk6Uhqp7p"
  # eosc system newaccount eosio battlefield4 --auth-key $WEBAUTHN_PUBLIC_KEY --stake-cpu 1 --stake-net 1 --transfer
  # eosc transfer eosio battlefield4 "200.0000 EOS"
  # sleep 0.6

  # echo ""
  # echo "About to push a WebAuthN signed tranasaction"
  # cd webauthn_signer
  # yarn -s run transfer || true
  # sleep 0.6
  # cd ..

  #
  ## EOSIO 2.0 protocol feature (WTMSIG_BLOCK_SIGNATURES)
  #

  # echo ""
  # echo -n "Activate protocol feature (WTMSIG_BLOCK_SIGNATURES)"
  # eosc tx create eosio activate '{"feature_digest":"299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707"}' -p eosio@active
  # sleep 1.2

  # ##Producer Schedule changed, with WTMSIG_BLOCK_SIGNATURES activated

  # echo ""
  # echo "Using eosio.bios contract temporarly to set producers"
  # eosc system setcontract eosio contracts/eosio.bios-1.5.2.wasm contracts/eosio.bios-1.5.2.abi
  # sleep 0.6

  # echo "Updating producers"
  # eosc tx create eosio setprods '{"schedule": [{"producer_name": "eosio", "block_signing_key":"EOS5MHPYyhjBjnQZejzZHqHewPWhGTfQWSVTWYEhDmJu4SXkzgweP"}]}' -p eosio@active
  # sleep 1.8

  # echo "Returning eosio contract to standard eosio.system contract"
  # eosc system setcontract eosio contracts/eosio.system-1.7.0-rc1.wasm contracts/eosio.system-1.7.0-rc1.abi
  # sleep 0.6

  echo ""
  echo "Exiting in 1 sec"
  sleep 1

  if [[ $nodeos_pid != "" ]]; then
    kill -s TERM $nodeos_pid &> /dev/null || true
    sleep 0.5
  fi

  # Print Log Files
  echo "Inspect log files"
  echo " Deep Mind logs: cat $deep_mind_log_file"
  echo " Nodeos logs: cat $nodeos_log_file"
  echo " eosc boot logs: cat $eosc_boot_log_file"
  echo ""
}

main $@

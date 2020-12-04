#!/bin/bash

set -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT=`pwd`
PID=
CONTAINER_NAME=

finish() {
    set +e
    echo "Cleaning up"
    [[ $PID != "" ]] && (kill -s TERM $PID &> /dev/null || true)
    [[ $CONTAINER_NAME != "" ]] && (docker kill $CONTAINER_NAME &> /dev/null || true)
}

main() {
  target="$1"
  eos_bin_or_docker="$2"

  if [[ ! -d "$ROOT/$target" ]]; then
      echo "The target dirctory '$ROOT/$target' does not exist, check first provided argument."
      exit 1
  fi

  run_mode=${RUN_MODE:-"all"}

  if [[ ${run_mode} == "all" || ${run_mode} == "only_generate" ]]; then
    if [[ "$eos_bin_or_docker" == "" ]]; then
      echo "Specify the path to nodeos, or a nodeos Docker image"
      exit 1
    fi

    echo "Copying blocks.log file from 'boot' as data to fully sync"
    rm -rf "$ROOT/$target/blocks/" "$ROOT/$target/protocol_features/" "$ROOT/$target/state/"
    cp -a "$ROOT/../boot/$target/blocks" "$ROOT/$target/"
    rm -rf "$ROOT/$target/blocks/reversible"
    cp -a "$ROOT/../boot/$target/protocol_features" "$ROOT/$target/"

    # Remove the old nodeos log file, we create a new empty one right away to avoid errors on first `cat`
    rm -rf "$ROOT/$target/nodeos.log"
    touch "$ROOT/$target/nodeos.log"

    # Trap exit signal and close any remaining jobs
    trap "finish" EXIT

    if [ -f $eos_bin_or_docker ]; then
        echo "Starting local instance for compare"
        ($eos_bin_or_docker --data-dir=$ROOT/$target --config-dir=$ROOT/$target --replay-blockchain > "$ROOT/$target/actual.dmlog" 2> "$ROOT/$target/nodeos.log") &
        PID=$!

        echo ""
        wait_for_final_block "cat $ROOT/$target/nodeos.log"
        kill -s TERM $PID &> /dev/null || true
    else
        echo "Starting a Docker container for compare"
        CONTAINER_NAME=deep-mind-compare
        docker kill $CONTAINER_NAME 2> /dev/null || true
        docker run \
            --rm \
            --name $CONTAINER_NAME \
            -v $ROOT/$target:/app \
            $eos_bin_or_docker \
            /bin/bash -c "nodeos --data-dir=/app --config-dir=/app --replay-blockchain > /app/actual.dmlog 2> /app/nodeos.log" &

        echo ""
        wait_for_final_block "cat $ROOT/$target/nodeos.log"
        docker kill $CONTAINER_NAME &> /dev/null || true
    fi
  fi

  if [[ ${run_mode} == "all" || ${run_mode} == "only_compare" ]]; then
    cd "$ROOT"
    echo "Performing sanity check to ensure new version is identical to reference version ..."
    go run compare.go "$target"
  fi
}

# wait_for_final_block <log_command>
wait_for_final_block() {
  log_command="$1"
  echo "Waiting for nodeos to fully sync"

  set +e
  while true; do
    result=`$log_command | grep -E "Blockchain started"`
    if [[ $result != "" ]]; then
        echo ""
        break
    fi

    echo "Giving 5s more to nodeos to fully sync"
    sleep 5
  done
  set -e

  echo "The nodeos process has fully synced"
}

main $@
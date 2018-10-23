#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EOS_BIN_OR_DOCKER="$1"
LOG_FILE=${LOG_FILE:-"/tmp/battlefield.log"}

if [ "$EOS_BIN_OR_DOCKER" == "" ]; then
    echo "Specify the path to nodeos, or a nodeos Docker image"
    exit 1
fi

rm -rf "$ROOT/blocks/" "$ROOT/state/"
cp -av "$ROOT/../boot/blocks" "$ROOT/"
rm -rf "$ROOT/blocks/reversible"

if [ -f $EOS_BIN_OR_DOCKER ]; then
    # Execute a local instance
    $EOS_BIN_OR_DOCKER --data-dir=$ROOT --config-dir=$ROOT --replay-blockchain > "$ROOT/output.log" &
    PID=$!

    sleep 10
    kill $PID
else
    # Assume it's a Docker image name
    CONTAINER_NAME=deep-mind-compare
    docker kill $CONTAINER_NAME 2> /dev/null || true
    docker run \
        --rm \
        --name $CONTAINER_NAME \
        -v $ROOT:/app \
        $EOS_BIN_OR_DOCKER \
        /bin/bash -c "/opt/eosio/bin/nodeos --data-dir=/app --config-dir=/app --replay-blockchain > /app/output.log" &

    sleep 10
    docker kill $CONTAINER_NAME
fi

OUTPUT_FILE="$ROOT/output.log"
REFERENCE_FILE="$ROOT/reference.log"
DIFF_FILE="$ROOT/diff.patch"

sed -i.bak -e 's/,"elapsed":[0-9]*,"/,"elapsed":0,"/g' "$OUTPUT_FILE"
sed -i.bak -e 's/"thread_name":"thread-[0-9]*","timestamp":"[^"]*"}/"thread_name":"thread-0","timestamp":"9999-99-99T99:99:99.999"}/g' "$OUTPUT_FILE"
sed -i.bak -e 's/,"line":[0-9]*,"/,"line":0,"/g' "$OUTPUT_FILE"
rm -rf "$OUTPUT_FILE.bak"

diff -u "$REFERENCE_FILE" "$OUTPUT_FILE" > "$DIFF_FILE"

if [ "$(cat $DIFF_FILE | wc -l | tr -d ' ')" != "0" ]; then
    echo "Some differences found between deep-mind reference log and logs produced by this build"
    printf "Check them right now? (y/N) "
    read value

    if [[ $value == "y" || $value == "yes", || $value == "Y" ]]; then
        viewer=${LESS:-less}
        $viewer $DIFF_FILE
    else
        echo "Perfect, you can check them later at:"
        echo "$DIFF_FILE"
    fi

    exit 1
else
    echo "No differences found with this version of the deep-mind instrumentation and the reference log."
fi

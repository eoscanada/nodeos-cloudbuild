#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

# Ubuntu 18.04
gcloud builds submit . \
    --config eos-vanilla.cb.yaml \
    --substitutions _IMAGE_TAG=ubuntu-18.04 \
    --timeout 1h \
    --machine-type=n1-highcpu-32 \
    --async

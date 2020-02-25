#!/bin/bash -x

# This step builds system contracts keeping only artifacts required for production,
# through `eosio.wasmsdk`.

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

gcloud builds submit . --config eosio-contracts.cb.yaml --timeout 8h --substitutions _SOURCE_BRANCH=v2 --machine-type=n1-highcpu-32

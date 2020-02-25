#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

[[ ! -d $ROOT/build ]] && mkdir $ROOT/build

gcloud builds submit . --config eosio-base.cb.yaml --substitutions _IMAGE_TAG=centos-7.7 --timeout 1h --machine-type=n1-highcpu-32 --async
gcloud builds submit . --config eosio-base.cb.yaml --substitutions _IMAGE_TAG=ubuntu-16.04 --timeout 1h --machine-type=n1-highcpu-32 --async
gcloud builds submit . --config eosio-base.cb.yaml --substitutions _IMAGE_TAG=ubuntu-18.04 --timeout 1h --machine-type=n1-highcpu-32 --async

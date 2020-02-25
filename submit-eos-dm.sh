#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export CLOUDSDK_CORE_PROJECT=eoscanada-shared-services

# CentOS 7.7
if [[ $BUILD_ALL == true ]]; then
    gcloud builds submit . \
        --config eos-dm.cb.yaml \
        --substitutions _IMAGE_TAG=centos-7.7,_OS=el7,_PKGTYPE=rpm \
        --timeout 1h \
        --machine-type=n1-highcpu-32 \
        --async
fi

# Ubuntu 16.04
if [[ $BUILD_ALL == true ]]; then
    gcloud builds submit . \
        --config eos-dm.cb.yaml \
        --substitutions _IMAGE_TAG=ubuntu-16.04,_OS=ubuntu-16.04,_PKGTYPE=deb \
        --timeout 1h \
        --machine-type=n1-highcpu-32 \
        --async
fi

# Ubuntu 18.04
gcloud builds submit . \
    --config eos-dm.cb.yaml \
    --substitutions _IMAGE_TAG=ubuntu-18.04,_OS=ubuntu-18.04,_PKGTYPE=deb \
    --timeout 1h \
    --machine-type=n1-highcpu-32 \
    --async

ARG EOSIO_BUILDENV_TAG

# We use the eosio-buildenv since it fits with wax chain (which is on 1.8.x)
FROM gcr.io/eoscanada-shared-services/eosio-buildenv:$EOSIO_BUILDENV_TAG as builder

ARG SRCTAG
ARG PATCHES
ARG REPOSITORY=https://github.com/worldwide-asset-exchange/wax-blockchain.git

COPY patches /patches

RUN git clone -b $SRCTAG --depth 1 $REPOSITORY --recursive eos \
    && cd eos \
    && echo PATCHING... && for patch in $PATCHES; do echo APPLYING PATCH $patch; patch -p1 < /patches/$patch; done && echo PATCHED \
    && echo "$SRCTAG:$(git rev-parse HEAD)" > /etc/eosio-version \
    && echo $REPOSITORY ref $SRCTAG revision `git describe --always --long` > /etc/eosio-build-version \
    && ./scripts/eosio_build.sh -y -s EOS -i "/opt/eosio/" -P \
    && ./scripts/eosio_install.sh
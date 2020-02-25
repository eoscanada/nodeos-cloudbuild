ARG BOS_FULL_TAG

FROM gcr.io/eoscanada-shared-services/boscore-bos-full:$BOS_FULL_TAG as builder

FROM ubuntu:18.04

COPY --from=builder /usr/local/lib/* /usr/local/lib/
COPY --from=builder /opt/eos/bin /opt/eosio/bin
COPY --from=builder /etc/bos-version /etc
COPY --from=builder /etc/bos-build-version /etc
COPY --from=builder /bos/Docker/nodeosd.sh /opt/eosio/bin/nodeosd.sh

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /opt/eosio/bin/nodeosd.sh

VOLUME /opt/eosio/bin/data-dir

ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

FROM centos:7.7.1908

ARG VERSION

WORKDIR /workspace

LABEL maintainer="dfuse Team"
LABEL description="Image containing the EOSIO development toolchain for EOS Blockchains" \
    version="${VERSION}" \
    packageName="eosio"

# Copy the package file from the context to our working directory
COPY ./*.rpm .

RUN yum install -y *.rpm && rm -rf *.rpm

# ARG EOS_FULL_TAG

# FROM gcr.io/eoscanada-shared-services/eosio-eos-full:$EOS_FULL_TAG as builder

# FROM ubuntu:18.04

# COPY --from=builder /usr/local/lib/* /usr/local/lib/
# COPY --from=builder /opt/eosio/bin /opt/eosio/bin
# COPY --from=builder /etc/eosio-version /etc
# COPY --from=builder /etc/eosio-build-version /etc

# RUN apt-get update \
#     && DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates \
#     && rm -rf /var/lib/apt/lists/*

# VOLUME /opt/eosio/bin/data-dir

# ENV PATH /opt/eosio/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

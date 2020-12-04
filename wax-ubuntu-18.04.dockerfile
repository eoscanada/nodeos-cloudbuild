FROM ubuntu:18.04

ARG VERSION

WORKDIR /workspace

LABEL maintainer="dfuse Team"
LABEL description="Image containing the EOSIO binaries for EOS Blockchains" \
    version="${VERSION}" \
    packageName="eosio"

# Copy the package file from the context to our working directory
COPY ./*.deb .

RUN apt-get update \
    && apt-get install -y openssl ca-certificates ./*.deb \
    && rm -rf *.deb \
    && apt-get clean

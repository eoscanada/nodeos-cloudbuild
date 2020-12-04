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

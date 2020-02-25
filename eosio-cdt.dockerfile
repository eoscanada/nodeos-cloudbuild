FROM ubuntu:18.04

ARG VERSION
ARG PACKAGE_URL

WORKDIR /workspace

LABEL description="Image containing the eosio.cdt development toolchain for EOS Blockchains" \
      version="${VERSION}" \
      packageName="eosio-cdt"

LABEL maintainer="Alexandre Bourget <alex@eoscanada.com>" \
      maintainer="Francois Proulx <francois@eoscanada.com>" \
      maintainer="Matthieu Vachon <matt@eoscanada.com>"

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
  && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y make cmake g++ openssl ca-certificates wget \
  && rm -rf /var/lib/apt/lists/*

RUN wget -O eosio-cdt-${VERSION}.deb "${PACKAGE_URL}" \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y ./eosio-cdt-${VERSION}.deb \
  && rm -rf ./eosio-cdt-${VERSION}.deb

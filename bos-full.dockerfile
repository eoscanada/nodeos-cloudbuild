ARG SRCTAG

FROM boscore/builder

ARG SRCTAG
ARG PATCHES
ARG REPOSITORY=https://github.com/boscore/bos.git

ENV OPENSSL_ROOT_DIR /usr/include/openssl

COPY patches /patches

RUN git clone -b $SRCTAG --depth 1 $REPOSITORY --recursive \
    && cd bos \
    && echo PATCHING... && for patch in $PATCHES; do echo APPLYING PATCH $patch; patch -p1 < /patches/$patch; done && echo PATCHED \
    && echo "$SRCTAG:$(git rev-parse HEAD)" > /etc/bos-version \
    && echo $REPOSITORY ref $SRCTAG revision `git describe --always --long` > /etc/bos-build-version \
    && cmake -H. -B"/tmp/build" -GNinja \
       -DCMAKE_BUILD_TYPE=Release \
       -DWASM_ROOT=/opt/wasm \
       -DCMAKE_CXX_COMPILER=clang++ \
       -DCMAKE_C_COMPILER=clang \
       -DOPENSSL_ROOT_DIR="${OPENSSL_ROOT_DIR}" \
       -DCMAKE_INSTALL_PREFIX=/opt/eos \
       -DBUILD_MONGO_DB_PLUGIN=false \
       -DCORE_SYMBOL_NAME=BOS \
    && cp --remove-destination `readlink /usr/lib/x86_64-linux-gnu/libz.so` /usr/lib/x86_64-linux-gnu/libz.so \
    && cp --remove-destination `readlink /usr/lib/x86_64-linux-gnu/libbz2.so` /usr/lib/x86_64-linux-gnu/libbz2.so \
    && cmake --build /tmp/build --target install

ENV BOOST /usr/local/include
ENV EOSIO_ROOT=/opt/eosio
ENV INSTALL_PREFIX /opt/eos
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PREFIX /opt

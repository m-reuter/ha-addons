ARG BUILD_FROM
FROM $BUILD_FROM as builder

ENV LANG C.UTF-8

# install packages
RUN apk add --no-cache \
    build-base \
    git \
    util-linux-dev \
    cmake \
    json-c-dev \
    libmicrohttpd-dev \
    openssl-dev \
    curl-dev \
    gnutls-dev \
    libgcrypt-dev \
    cyrus-sasl-dev \
    libunistring-dev \
    mosquitto-dev \
    autoconf \
    automake \
    libtool
    
WORKDIR /vzlogger

# build libsml
RUN git clone https://github.com/volkszaehler/libsml.git --depth 1 \
 && make install -C libsml/sml

# build libmbus
RUN git clone https://github.com/rscada/libmbus.git --depth 1 \
 && cd libmbus \
 && ./build.sh \
 && make install \
 && cd ..

# build vzlogger
RUN git clone https://github.com/volkszaehler/vzlogger.git --depth 1 \
 && cd vzlogger \
 && cmake . -DBUILD_TEST=off \
 && make \
 && make install


# Create final and small Image
FROM $BUILD_FROM

LABEL Description="vzlogger"

RUN apk add --no-cache \
    libcurl \
    gnutls \
    libsasl \
    libuuid \
    openssl-dev \
    libgcrypt \
    libmicrohttpd \
    libltdl \
    libatomic \
    json-c \
    leptonica \
    mosquitto-dev \
    libunistring

# libsml is linked statically => no need to copy
COPY --from=builder /usr/local/bin/vzlogger /usr/local/bin/vzlogger
COPY --from=builder /usr/local/lib/libmbus.so* /usr/local/lib/

# Copy data for add-on
COPY vzlogger.conf /
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

